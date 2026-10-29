import 'package:flutter/material.dart';

/// Extension and helper utilities to guarantee that TextEditingController instances
/// always maintain valid, bounded cursor selections and never fall into the
/// invalid selection state (offset: -1) that causes Flutter to discard touch coordinates
/// or trigger unintended full text selection on tap.
extension SafeTextEditingController on TextEditingController {
  /// Safely updates the text and ensures a valid collapsed selection.
  /// If [targetOffset] is provided, clamps it between 0 and newText.length.
  /// Otherwise, preserves the current offset if within bounds, or places it at the end.
  void safeSetText(String? newText, {int? targetOffset}) {
    final content = newText ?? '';
    final int safeOffset;
    if (targetOffset != null) {
      safeOffset = targetOffset.clamp(0, content.length);
    } else if (selection.isValid && selection.extentOffset <= content.length) {
      safeOffset = selection.extentOffset;
    } else {
      safeOffset = content.length;
    }

    value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
  }

  /// Collapses selection to the end of the text.
  void collapseToEnd() {
    selection = TextSelection.collapsed(offset: text.length);
  }

  /// Collapses selection to a specific offset.
  void collapseTo(int offset) {
    selection = TextSelection.collapsed(offset: offset.clamp(0, text.length));
  }
}

/// Helper function to create a TextEditingController pre-populated with text
/// and an explicit, valid collapsed selection at the end.
TextEditingController createSafeController({String? text}) {
  final content = text ?? '';
  return TextEditingController.fromValue(
    TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    ),
  );
}
