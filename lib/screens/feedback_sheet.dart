import 'package:flutter/material.dart';

import '../main.dart';
import '../services/locale_service.dart';
import '../services/review_service.dart';

String _t(String tr, String en, String ar) =>
    LocaleService.instance.tr(tr, en, ar);

/// "Send feedback" sheet: the message goes to the developer by e-mail.
Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _msg = TextEditingController();
  final _email = TextEditingController();
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _msg.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_msg.text.trim().length < 2 || _sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final ok = await ReviewService.instance.sendFeedback(_msg.text, _email.text);
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(_t('Teşekkürler! Mesajın ulaştı.',
            'Thank you! Your message was sent.', 'شكرًا! تم إرسال رسالتك.')),
      ));
    } else {
      setState(() {
        _sending = false;
        _failed = true;
      });
    }
  }

  InputDecoration _box(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(12),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t('Öneri / sorun bildir', 'Send feedback',
                  'اقتراح / الإبلاغ عن مشكلة'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                'Mesajın doğrudan geliştiriciye gider. Bir sorun varsa ne olduğunu yaz, düzeltelim.',
                'Your message goes straight to the developer. If something is wrong, tell us and we will fix it.',
                'رسالتك تصل مباشرة إلى المطوّر. إن واجهت مشكلة فاكتبها لنا وسنصلحها.',
              ),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _msg,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: _box(_t('Mesajın…', 'Your message…', 'رسالتك…')),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _box(_t(
                'E-postan (cevap istersen, isteğe bağlı)',
                'Your email (optional, if you want a reply)',
                'بريدك الإلكتروني (اختياري، إن أردت ردًا)',
              )),
            ),
            if (_failed) ...[
              const SizedBox(height: 10),
              Text(
                _t(
                  'Gönderilemedi. İnternet bağlantını kontrol edip tekrar dene.',
                  'Could not send. Check your internet connection and try again.',
                  'تعذّر الإرسال. تحقّق من اتصالك بالإنترنت وحاول مرة أخرى.',
                ),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed:
                  _msg.text.trim().length >= 2 && !_sending ? _send : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_t('Gönder', 'Send', 'إرسال'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
