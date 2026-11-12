import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/extra_translations.dart';
import 'package:sesli_tesbih/services/review_service.dart';

void main() {
  const day = 24 * 60 * 60 * 1000;
  final now = DateTime(2026, 11, 10).millisecondsSinceEpoch;

  bool ask({int rounds = 5, int days = 3, int asks = 0, int lastAskMs = 0}) =>
      ReviewService.shouldAsk(
          rounds: rounds, days: days, asks: asks, lastAskMs: lastAskMs, nowMs: now);

  test('asks a regular user who has finished several rounds', () {
    expect(ask(), isTrue);
  });

  test('not on the first day or before 3 finished rounds', () {
    expect(ask(days: 1), isFalse);
    expect(ask(rounds: 2), isFalse);
  });

  test('at most 3 times, at least 120 days apart', () {
    expect(ask(asks: 3), isFalse);
    expect(ask(asks: 1, lastAskMs: now - 30 * day), isFalse);
    expect(ask(asks: 1, lastAskMs: now - 121 * day), isTrue);
  });

  test('feedback strings exist in every extra language', () {
    const keys = [
      'Send feedback',
      'Rate the app',
      'Your message…',
      'Your email (optional, if you want a reply)',
      'Send',
      'Thank you! Your message was sent.',
      'Could not send. Check your internet connection and try again.',
    ];
    for (final lang in ['id', 'ur', 'fr']) {
      for (final k in keys) {
        expect(kExtraTranslations[lang]![k], isNotNull, reason: '$lang: $k');
      }
    }
  });
}
