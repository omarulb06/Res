import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';

/// Shows a sleek 4-6 digit PIN dialog. Returns the entered code on success,
/// or `null` if cancelled. The caller is responsible for validating the PIN
/// against the venue's accessCode.
class PinDialog extends StatefulWidget {
  final String venueTitle;
  final String expectedCode;

  const PinDialog({
    super.key,
    required this.venueTitle,
    required this.expectedCode,
  });

  static Future<bool> prompt(
    BuildContext context, {
    required String venueTitle,
    required String expectedCode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PinDialog(
        venueTitle: venueTitle,
        expectedCode: expectedCode,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(S s) {
    final code = _ctrl.text.trim();
    if (code.length < 4 || code.length > 6) {
      setState(() => _error = s.enterPinLength);
      return;
    }
    if (code != widget.expectedCode) {
      setState(() => _error = s.incorrectCode);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: CircleAvatar(
        radius: 28,
        backgroundColor: cs.secondaryContainer,
        child: Icon(Icons.lock_rounded,
            color: cs.onSecondaryContainer, size: 28),
      ),
      title: Text(s.privateVenue),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '“${widget.venueTitle}” ${s.privateVenueDescription}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(s),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => _submit(s),
          child: Text(s.unlock),
        ),
      ],
    );
  }
}
