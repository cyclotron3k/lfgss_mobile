import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showPageJumpDialog({
  required BuildContext context,
  required TextEditingController controller,
  required int maxPageNumber,
}) {
  return showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Jump to page...'),
      content: Row(
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                final number = int.tryParse(value);
                if (number != null) {
                  final text = number.clamp(1, maxPageNumber).toString();
                  final selection = TextSelection.collapsed(
                    offset: text.length,
                  );
                  controller.value = TextEditingValue(
                    text: text,
                    selection: selection,
                  );
                }
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Page number',
              ),
            ),
          ),
          Text('/ $maxPageNumber')
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, controller.text),
          child: const Text('GO'),
        ),
      ],
    ),
  );
}

Future<String?> showThreadSearchDialog({
  required BuildContext context,
  required TextEditingController controller,
}) {
  return showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Search in thread'),
      content: SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          maxLength: 512,
          decoration: const InputDecoration(
            counterText: '',
            hintText: 'Search for...',
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, controller.text),
          child: const Text('GO'),
        ),
      ],
    ),
  );
}
