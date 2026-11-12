import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_service.dart';

/// Store rating + direct feedback to the developer.
///
/// Store rules (Google Play in-app review guidelines, App Store 5.6.1):
/// the native rating card is shown directly — never after a "do you like
/// the app?" question, and feedback never decides who sees the card.
/// Feedback is a separate menu item that is always available.
///
/// The card is shown at a "happy moment": the user closes the counter
/// after finishing a round, has finished several rounds overall and has
/// used the app on more than one day. The OS may still decide not to
/// show it (Apple: max 3 times a year; Google: its own quota).
class ReviewService {
  static final ReviewService instance = ReviewService._();
  ReviewService._();

  static const appStoreId = '6768603349';
  static const feedbackUrl =
      'https://uygulama-geri-bildirim.ssaglamess.workers.dev/gonder';

  static const minRounds = 3;
  static const minDays = 2;
  static const maxAsks = 3;
  static const askGap = Duration(days: 120);

  static const _kRounds = 'rv_rounds';
  static const _kDays = 'rv_days';
  static const _kLastDay = 'rv_last_day';
  static const _kAsks = 'rv_asks';
  static const _kLastAsk = 'rv_last_ask_ms';

  bool _roundThisSession = false;

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _touchDay(SharedPreferences p) async {
    final today = _day(DateTime.now());
    if (p.getString(_kLastDay) == today) return;
    await p.setString(_kLastDay, today);
    await p.setInt(_kDays, (p.getInt(_kDays) ?? 0) + 1);
  }

  /// Call once at app start: counts distinct days of use.
  Future<void> recordAppOpen() async {
    try {
      await _touchDay(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// A dhikr round (target count) was just completed.
  Future<void> noteRoundCompleted() async {
    _roundThisSession = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kRounds, (p.getInt(_kRounds) ?? 0) + 1);
      await _touchDay(p);
    } catch (_) {}
  }

  @visibleForTesting
  static bool shouldAsk({
    required int rounds,
    required int days,
    required int asks,
    required int lastAskMs,
    required int nowMs,
  }) =>
      rounds >= minRounds &&
      days >= minDays &&
      asks < maxAsks &&
      (lastAskMs == 0 || nowMs - lastAskMs >= askGap.inMilliseconds);

  /// The counter screen was closed. If a round was finished in it, this is
  /// the moment to show the native store rating card.
  Future<void> onCounterClosed() async {
    if (!_roundThisSession) return;
    _roundThisSession = false;
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final asks = p.getInt(_kAsks) ?? 0;
      if (!shouldAsk(
        rounds: p.getInt(_kRounds) ?? 0,
        days: p.getInt(_kDays) ?? 0,
        asks: asks,
        lastAskMs: p.getInt(_kLastAsk) ?? 0,
        nowMs: now,
      )) {
        return;
      }
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      // Let the route pop animation finish first.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await p.setInt(_kAsks, asks + 1);
      await p.setInt(_kLastAsk, now);
      await review.requestReview();
    } catch (_) {}
  }

  /// "Rate the app" menu item: opens the store page (user-initiated).
  Future<void> openStorePage() async {
    try {
      await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
    } catch (_) {}
  }

  /// Sends the message to the developer's e-mail. True when it arrived.
  Future<bool> sendFeedback(String message, String email) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      String version = '';
      try {
        final info = await PackageInfo.fromPlatform();
        version = '${info.version} (${info.buildNumber})';
      } catch (_) {}
      final body = jsonEncode({
        'app': 'tespih',
        'message': message.trim(),
        'email': email.trim(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'version': version,
        'lang': LocaleService.instance.language,
        'country': ui.PlatformDispatcher.instance.locale.countryCode ?? '',
      });
      final req = await client
          .postUrl(Uri.parse(feedbackUrl))
          .timeout(const Duration(seconds: 15));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 20));
      await res.drain<void>();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
