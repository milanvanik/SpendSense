import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spendsense/authentication/login_screen.dart';
import 'package:spendsense/custom_widgets/common_auth_button.dart';
import 'package:spendsense/custom_widgets/common_textfield.dart';
import 'package:spendsense/models/user_details.dart';
import 'package:spendsense/presentation/dashboard_screen.dart';
import 'package:spendsense/utils/appconstant.dart';
import 'package:spendsense/utils/firestore_collection.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  final _firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>]).{6,}$',
    );
    if (!passwordRegex.hasMatch(value)) {
      return "Password must be 6+ chars, with 1 uppercase & 1 symbol.";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _storeUserdata({required UserDetails userDetails}) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Check if the user document already exists.
    final docRef = await firestore
        .collection(FirestoreCollection.usersCollection)
        .doc(userDetails.uid)
        .get();

    if (docRef.exists) {
      print("User document already exists.");
      return;
    }

    final batch = firestore.batch();

    // 2. Create the main user profile document.
    final userDoc = firestore
        .collection(FirestoreCollection.usersCollection)
        .doc(userDetails.uid);
    batch.set(userDoc, userDetails.toJson());

    // 3. Get a reference to the user's personal categories subcollection.
    final categoriesSubcollection = userDoc.collection(
      FirestoreCollection.categoriesCollection,
    );

    // 4. Create each default category one by one.
    batch.set(categoriesSubcollection.doc('food'), {
      'id': 'food',
      'name': 'Food & Dining',
      'type': 'expense',
      'icon': 'fastfood',
      'color': 'FF455A64',
    });

    batch.set(categoriesSubcollection.doc('bills'), {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'type': 'expense',
      'icon': 'receipt_long',
      'color': 'FFFF7043',
    });

    batch.set(categoriesSubcollection.doc('salary'), {
      'id': 'salary',
      'name': 'Salary',
      'type': 'income',
      'icon': 'work',
      'color': 'FF66BB6A',
    });

    await batch.commit();
    print("User setup complete!");
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredentials = await _firebaseAuth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .timeout(const Duration(seconds: 15));

        final user = userCredentials.user;
        if (user == null) {
          throw Exception("Failed to register");
        }

        // Create user details and store them in Firestore
        try {
          await _storeUserdata(
            userDetails: UserDetails(
              uid: user.uid,
              email: user.email ?? _emailController.text.trim(),
            ),
          ).timeout(const Duration(seconds: 10)); // Timeout after 10s
        } catch (e) {
          // If Firestore write hangs or fails, rollback the user creation
          // to prevent ghost accounts with no database data.
          await user.delete();
          throw Exception(
            "Database unreachable! Have you created the Firestore Database in the Firebase Console?",
          );
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (_) => false,
        );
        Appconstant.showSnackBar(
          context,
          message: "Account created successfully",
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == "weak-password") {
          Appconstant.showSnackBar(
            context,
            message: "Password is too weak",
            isSuccess: false,
          );
        } else if (e.code == "email-already-in-use") {
          Appconstant.showSnackBar(
            context,
            message: "Email is already in use",
            isSuccess: false,
          );
        } else {
          Appconstant.showSnackBar(
            context,
            message: e.message ?? "An error occurred",
            isSuccess: false,
          );
        }
      } catch (error) {
        Appconstant.showSnackBar(
          context,
          message: error.toString().replaceAll("Exception: ", ""),
          isSuccess: false,
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  Image.asset(
                    "assets/images/logo/logo.png",
                    height: 149.h,
                    width: 149.w,
                  ),
                  Center(
                    child: Text(
                      "SpendSense",
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1B3253),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Center(
                    child: Text(
                      "Your Path to Financial Peace",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF80C0E2),
                      ),
                    ),
                  ),
                  SizedBox(height: 44.h),

                  CommonTextfield(
                    controller: _emailController,
                    hintText: "Email Address",
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.emailAddress,
                    icon: Icons.account_circle,
                    isPassword: false,
                    validator: _validateEmail,
                  ),

                  SizedBox(height: 20.h),
                  CommonTextfield(
                    controller: _passwordController,
                    hintText: "Password",
                    isPassword: true,
                    icon: Icons.remove_red_eye_outlined,
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.name,
                    validator: _validatePassword,
                  ),

                  SizedBox(height: 20.h),
                  CommonTextfield(
                    controller: _confirmPasswordController,
                    hintText: "Confirm Password",
                    isPassword: true,
                    icon: Icons.remove_red_eye_outlined,
                    textInputAction: TextInputAction.done,
                    textInputType: TextInputType.name,
                    validator: _validateConfirmPassword,
                  ),

                  SizedBox(height: 36.h),
                  CommonAuthButton(
                    buttonText: "Create Account",
                    onPressed: _handleRegistration,
                    backgroundColor: const Color(0xFF1B3253),
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 156.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            color: const Color(0xFF8A949D),
                          ),
                        ),
                        TextSpan(
                          text: "Login in",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1B3253),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
