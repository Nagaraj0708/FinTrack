import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Singleton service for scheduling and displaying local push notifications.
/// Covers alerts for: large transactions, high spend rate, and weekly summaries.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call this once on app start (before runApp or right after).
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Notification Channel Configs ──────────────────────────────────────────

  AndroidNotificationDetails get _transactionChannel =>
      const AndroidNotificationDetails(
        'fintrack_transactions',
        'Transaction Alerts',
        channelDescription: 'Alerts for large or notable transactions',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1C4532),
      );

  AndroidNotificationDetails get _budgetChannel =>
      const AndroidNotificationDetails(
        'fintrack_budget',
        'Budget & Spending Alerts',
        channelDescription: 'Alerts when spending exceeds your budget',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFEF4444),
      );

  AndroidNotificationDetails get _weeklyChannel =>
      const AndroidNotificationDetails(
        'fintrack_weekly',
        'Weekly Summary',
        channelDescription: 'Weekly financial summary digest',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1C4532),
      );

  // ── Public Trigger Methods ────────────────────────────────────────────────

  /// Call when a transaction > threshold is added.
  Future<void> notifyLargeTransaction({
    required String description,
    required int amount,
    required bool isExpense,
    int threshold = 5000,
  }) async {
    if (!_initialized) await init();
    if (amount < threshold) return;

    final sign = isExpense ? '-₹' : '+₹';
    await _plugin.show(
      1001,
      isExpense ? '💸 Large Expense Recorded' : '💰 Income Received',
      '$sign${_formatAmount(amount)} — $description',
      NotificationDetails(android: _transactionChannel),
    );
  }

  /// Call after each new expense to check if monthly spend rate is high.
  Future<void> notifyHighSpendRate({
    required int monthlyIncome,
    required int monthlyExpenses,
  }) async {
    if (!_initialized) await init();
    if (monthlyIncome == 0) return;

    final rate = (monthlyExpenses / monthlyIncome) * 100;
    if (rate >= 80) {
      await _plugin.show(
        1002,
        '⚠️ High Spending Alert',
        'You\'ve spent ${rate.toStringAsFixed(0)}% of your monthly income. Time to review!',
        NotificationDetails(android: _budgetChannel),
      );
    }
  }

  /// Call to send a weekly financial digest (call from a scheduler or on app open Monday).
  Future<void> notifyWeeklySummary({
    required int income,
    required int expenses,
    required int savings,
  }) async {
    if (!_initialized) await init();

    final rate = income > 0 ? ((savings / income) * 100).toStringAsFixed(0) : '0';
    await _plugin.show(
      1003,
      '📊 Your Weekly Summary',
      'Income: ₹${_formatAmount(income)} | Spent: ₹${_formatAmount(expenses)} | Saved: $rate%',
      NotificationDetails(android: _weeklyChannel),
    );
  }

  /// Cancel a specific notification by ID.
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancel all notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}

/// Global singleton accessor
final notificationService = NotificationService();
