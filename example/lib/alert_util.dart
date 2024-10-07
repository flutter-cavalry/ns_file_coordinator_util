import 'package:fc_quick_dialog/fc_quick_dialog.dart';
import 'package:flutter/material.dart';

Future<void> showWarningAlert(BuildContext context, String msg) async {
  await FcQuickDialog.info(
    context,
    content: msg,
    title: 'Warning',
    okText: 'OK',
  );
}

Future<void> showErrorAlert(BuildContext context, Object err) async {
  await FcQuickDialog.error(
    context,
    error: err,
    title: 'Error',
    okText: 'OK',
  );
}

Future<void> showInfoAlert(BuildContext context, String msg) async {
  await FcQuickDialog.info(
    context,
    content: msg,
    title: 'Info',
    okText: 'OK',
  );
}
