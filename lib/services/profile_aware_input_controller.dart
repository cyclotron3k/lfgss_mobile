import 'package:flutter/material.dart';

class ProfileAwareInputController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      TextSpan(children: _splitString(style), style: style);

  List<TextSpan> _splitString(style) {
    int startIndex = selection.baseOffset;
    int endIndex = selection.baseOffset;
    final nonSpace = RegExp(r'[^\s]');

    if (text.isEmpty ||
        startIndex < 0 ||
        startIndex != selection.extentOffset) {
      return _unformattedText(style);
    }

    while (startIndex > 0 && nonSpace.hasMatch(text[startIndex - 1])) {
      startIndex--;
    }

    if (startIndex >= text.length || text[startIndex] != "@") {
      return _unformattedText(style);
    }

    while (endIndex < text.length && nonSpace.hasMatch(text[endIndex])) {
      endIndex++;
    }

    if (startIndex == endIndex) {
      return _unformattedText(style);
    }

    final List<TextSpan> parts = [];

    if (startIndex > 0) {
      parts.add(TextSpan(
        text: text.substring(0, startIndex),
        style: style,
      ));
    }

    parts.add(TextSpan(
      text: text.substring(startIndex, endIndex),
      style: style!.copyWith(
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.solid,
        decorationColor: Colors.blue,
        decorationThickness: 3.0,
      ),
    ));

    if (endIndex < text.length - 1) {
      parts.add(TextSpan(
        text: text.substring(endIndex, text.length - 1),
        style: style,
      ));
    }
    return parts;
  }

  List<TextSpan> _unformattedText(TextStyle? style) {
    return [TextSpan(text: text, style: style)];
  }
}
