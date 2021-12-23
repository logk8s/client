import 'package:flutter/material.dart';
import 'custom_color_scheme.dart';

InputDecoration textInputDecoration(BuildContext context, String hintText) {
  return InputDecoration(
    //border: InputBorder.none,
    hintText: hintText,
    fillColor: Theme.of(context).colorScheme.editBackground,
    // textInputFillColor
    filled: true,
  );
}
