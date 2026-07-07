import 'package:flutter/services.dart';

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String inputText = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      if (inputText[i] != '/') {
        buffer.write(inputText[i]);
      }
    }

    final String cleanText = buffer.toString();
    final formattedBuffer = StringBuffer();

    for (int i = 0; i < cleanText.length; i++) {
      formattedBuffer.write(cleanText[i]);
      if (i == 1 && cleanText.length > 2) {
        formattedBuffer.write('/');
      }
    }

    final String formattedText = formattedBuffer.toString();

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
