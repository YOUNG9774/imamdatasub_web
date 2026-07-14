import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/providers/home_provider.dart'
    show unreadNotificationCountProvider;

// ── Notification prefs (persisted via Hive) ───────────────
final pushNotificationsEnabledProvider = StateProvider<bool>((ref) {
  final hive = ref.read(hiveStorageProvider);
  return hive.getSetting<bool>('notif_push', defaultValue: true) ?? true;
});

final promoNotificationsEnabledProvider = StateProvider<bool>((ref) {
  final hive = ref.read(hiveStorageProvider);
  return hive.getSetting<bool>('notif_promo', defaultValue: true) ?? true;
});

// ── In-app notification entity ────────────────────────────
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime date;
  final String? type;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          '',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      type: json['type']?.toString(),
      isRead: json['is_read'] == true || json['read'] == true,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      date: date,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

// ── Notification remote source ─────────────────────────────
final _notifRemoteProvider = Provider((ref) {
  return _NotifRemote(ref.read(dioClientProvider));
});

class _NotifRemote {
  const _NotifRemote(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get(AppEndpoints.notifications);
      final list =
          (response.data['data'] ?? response.data) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(AppEndpoints.markNotificationRead);
    } catch (_) {}
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post(
        AppEndpoints.registerFcmToken,
        data: {'token': token},
      );
    } catch (_) {}
  }
}

// ── FCM service ────────────────────────────────────────────
class FcmService {
  FcmService(this._ref);
  final Ref _ref;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'imam_datasub_notifications',
      'IMAM DATASUB',
      description: 'Transaction alerts and app notifications',
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register FCM token
    final token = await messaging.getToken();
    if (token != null) {
      await _saveAndRegisterToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_saveAndRegisterToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Increment unread count from background taps
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _ref.read(unreadNotificationCountProvider.notifier).state++;
    });
  }

  Future<void> _saveAndRegisterToken(String token) async {
    final secure = _ref.read(secureStorageProvider);
    await secure.saveFcmToken(token);
    final remote = _ref.read(_notifRemoteProvider);
    await remote.registerFcmToken(token);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'imam_datasub_notifications',
          'IMAM DATASUB',
          channelDescription: 'Transaction alerts and app notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );

    // Increment unread count
    _ref.read(unreadNotificationCountProvider.notifier).state++;
  }
}

final fcmServiceProvider = Provider<FcmService>(
    (ref) => FcmService(ref));

// ── Notifications list provider ────────────────────────────
class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final remote = _ref.read(_notifRemoteProvider);
    final notifications = await remote.getNotifications();
    state = AsyncValue.data(notifications);
    // Sync unread count
    final unread = notifications.where((n) => !n.isRead).length;
    _ref.read(unreadNotificationCountProvider.notifier).state = unread;
  }

  Future<void> markAllRead() async {
    final remote = _ref.read(_notifRemoteProvider);
    await remote.markAllRead();
    state = AsyncValue.data(
      state.valueOrNull
              ?.map((n) => n.copyWith(isRead: true))
              .toList() ??
          [],
    );
    _ref.read(unreadNotificationCountProvider.notifier).state = 0;
  }

  Future<void> refresh() => _load();
}

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier,
    AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsNotifier(ref);
});