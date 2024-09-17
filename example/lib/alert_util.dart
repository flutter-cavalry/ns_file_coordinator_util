import 'package:fc_material_alert/fc_material_alert.dart';
import 'package:flutter/material.dart';

Future<void> showWarningAlert(BuildContext context, String msg) async {
  await FcMaterialAlert.standard(
    context,
    content: msg,
    title: 'Warning',
    okText: 'OK',
  );
}

Future<void> showErrorAlert(BuildContext context, Object err) async {
  await FcMaterialAlert.error(
    context,
    err,
    title: 'Error',
    okText: 'OK',
  );
}

Future<void> showInfoAlert(BuildContext context, String msg) async {
  await FcMaterialAlert.standard(
    context,
    content: msg,
    title: 'Info',
    okText: 'OK',
  );
}
