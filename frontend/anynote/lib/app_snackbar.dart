import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackbar(
  String title,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) {
    return;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      content: Text('$title: $message'),
    ),
  );
}
