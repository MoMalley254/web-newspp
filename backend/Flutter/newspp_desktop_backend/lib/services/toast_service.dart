import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  showErrortoast(String toastMessage) {
    toastification.show(
      title: Text('Error $toastMessage.'),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  showWarningtoast(String toastMessage) {
    toastification.show(
      title: Text('$toastMessage.'),
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  showSuccesstoast(String toastMessage) {
    toastification.show(
      title: Text('$toastMessage.'),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  showProcessingtoast(String toastMessage, int toastDuration) {
    toastification.show(
      title: Text('$toastMessage.'),
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: Duration(seconds: toastDuration),
    );
  }

  showClickableSuccesstoast(
    String toastMessage,
    int toastDuration,
    VoidCallback clickFunction,
  ) {
    toastification.show(
      title: Text('$toastMessage.'),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: Duration(seconds: toastDuration),
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) {
          clickFunction();
        },
      ),
    );
  }
}
