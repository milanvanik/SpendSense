import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonTextfield extends StatefulWidget {
  const CommonTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.textInputType,
    this.isPassword = false,
    this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final bool isPassword;
  final IconData? icon;
  final FormFieldValidator<String>? validator;

  @override
  State<CommonTextfield> createState() => _CommonTextfieldState();
}

class _CommonTextfieldState extends State<CommonTextfield> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        textInputAction: widget.textInputAction,
        keyboardType: widget.textInputType,
        obscureText: widget.isPassword && _isObscured,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8A949D),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8A949D),
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : Icon(widget.icon, color: const Color(0xFF8A949D)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 14.h,
            horizontal: 20.w,
          ),
        ),
      ),
    );
  }
}
