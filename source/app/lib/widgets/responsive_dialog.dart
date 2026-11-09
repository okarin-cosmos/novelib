import 'package:flutter/widgets.dart';

double responsiveDialogHeight(
  BuildContext context,
  double preferred, {
  double minimum = 260,
}) => (MediaQuery.sizeOf(context).height - 180)
    .clamp(minimum, preferred)
    .toDouble();
