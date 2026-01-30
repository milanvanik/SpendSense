import 'package:flutter/material.dart';

class Appconstant {
  Appconstant._();
  static showSnackBar(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    final banner = MaterialBanner(
      content: Text(message, style: TextStyle(color: Colors.white)),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      contentTextStyle: const TextStyle(color: Colors.white),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
    messenger.showMaterialBanner(banner);
    Future.delayed(const Duration(seconds: 3), () {
      messenger.hideCurrentMaterialBanner();
    });
  }
}
