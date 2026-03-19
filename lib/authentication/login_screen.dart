import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spendsense/authentication/register_screen.dart';
import 'package:spendsense/custom_widgets/common_auth_button.dart';
import 'package:spendsense/custom_widgets/common_textfield.dart';
import 'package:spendsense/models/categories.dart';
import 'package:spendsense/models/user_details.dart';
import 'package:spendsense/presentation/dashboard_screen.dart';
import 'package:spendsense/utils/appconstant.dart';
import 'package:spendsense/utils/firestore_collection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final firebaseAuth = FirebaseAuth.instance;
  final googleSign = GoogleSignIn();
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      return "Password is invalid";
    }
    return null;
  }

  Future<void> _storeUserdata({required UserDetails userDetails}) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Check if the user document already exists to avoid overwriting data.
    final docRef = await firestore
        .collection(FirestoreCollection.usersCollection)
        .doc(userDetails.uid)
        .get();

    if (docRef.exists) {
      print("User document already exists.");
      return;
    }

    // Use a batch write to perform multiple operations automatically (all succeed or all fail).
    final batch = firestore.batch();

    // 2. Create the main user profile document.
    final userDoc = firestore
        .collection(FirestoreCollection.usersCollection)
        .doc(userDetails.uid);
    batch.set(userDoc, userDetails.toJson());

    // 3. Create default categories inside a 'categories' subcollection for this user.
    final categoriesSubcollection = userDoc.collection(
      FirestoreCollection.categoriesCollection,
    );

    // Default Expense Categories
    final expenseCategories = [
      CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        type: 'expense',
        icon: 'fastfood',
        color: 'FF455A64',
      ),
      CategoryModel(
        id: 'bills',
        name: 'Bills & Utilities',
        type: 'expense',
        icon: 'receipt_long',
        color: 'FFFF7043',
      ),
      CategoryModel(
        id: 'transport',
        name: 'Transportation',
        type: 'expense',
        icon: 'commute',
        color: 'FF5C6BC0',
      ),
      CategoryModel(
        id: 'shopping',
        name: 'Shopping',
        type: 'expense',
        icon: 'shopping_bag',
        color: 'FF26A69A',
      ),
    ];

    // Default Income Category
    final incomeCategories = [
      CategoryModel(
        id: 'salary',
        name: 'Salary',
        type: 'income',
        icon: 'work',
        color: 'FF66BB6A',
      ),
    ];

    // Add each category to the batch
    for (var category in expenseCategories) {
      final newCategoryDoc = categoriesSubcollection.doc(category.id);
      batch.set(newCategoryDoc, category.toJson());
    }

    for (var category in incomeCategories) {
      final newCategoryDoc = categoriesSubcollection.doc(category.id);
      batch.set(newCategoryDoc, category.toJson());
    }

    // Commit the batch to save all data at once.
    await batch.commit();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await firebaseAuth
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .timeout(const Duration(seconds: 15));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
          (_) => false,
        );
        Appconstant.showSnackBar(context, message: "LoggedIn successfully");
      } on FirebaseAuthException catch (e) {
        if (e.code == "invalid-credential") {
          Appconstant.showSnackBar(
            context,
            message: "invalid email or password",
            isSuccess: false,
          );
        } else {
          Appconstant.showSnackBar(
            context,
            isSuccess: false,
            message: e.toString(),
          );
        }
      } catch (e) {
        Appconstant.showSnackBar(
          context,
          message: e.toString(),
          isSuccess: false,
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final googleUser = await googleSign.signIn();
      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credentials,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return;

      await _storeUserdata(
        userDetails: UserDetails(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          firstName: firebaseUser.displayName?.split(" ").first,
          lastName: firebaseUser.displayName?.split(" ").last,
        ),
      );

      if (!mounted) return;
      Appconstant.showSnackBar(
        context,
        message: "Sign in successful",
        isSuccess: true,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        Appconstant.showSnackBar(
          context,
          message: e.toString(),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                    validator: _validateEmail,
                    controller: _emailController,
                    hintText: "Email Address",
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.emailAddress,
                    icon: Icons.account_circle,
                    isPassword: false,
                  ),

                  SizedBox(height: 20.h),
                  CommonTextfield(
                    validator: _validatePassword,
                    controller: _passwordController,
                    hintText: "Password",
                    isPassword: true,
                    icon: Icons.remove_red_eye_outlined,
                    textInputAction: TextInputAction.done,
                    textInputType: TextInputType.name,
                  ),

                  SizedBox(height: 36.h),
                  CommonAuthButton(
                    buttonText: "LOGIN SECURELY",
                    onPressed: _handleSignIn,
                    backgroundColor: Color(0xFF1B3253),
                    isLoading: isLoading,
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Color(0xFF8A949D),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),
                  Center(
                    child: Text(
                      "OR",
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Color(0xFF8A949D),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),
                  CommonAuthButton(
                    buttonText: "Continue with Google",
                    onPressed: _signInWithGoogle,
                    backgroundColor: Color(0xFF80C0E2),
                    isLoading: isLoading,
                  ),

                  SizedBox(height: 56.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            color: const Color(0xFF8A949D),
                          ),
                        ),
                        TextSpan(
                          text: "Create new",
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
                                  builder: (context) => RegisterScreen(),
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
