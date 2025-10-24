import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';
import '../models/inventory_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  String get baseUrl => AppConfig.baseUrl;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inizializza timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));

      // Configurazione Android
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurazione iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('✓ NotificationService inizializzato');
    } catch (e) {
      debugPrint('❌ Errore inizializzazione notifiche: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notifica tapped: ${response.payload}');
    // TODO: Navigare alla schermata appropriata basandosi sul payload
  }

  Future<bool> requestPermissions() async {
    try {
      // Android 13+ richiede permesso runtime
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Errore richiesta permessi: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'shopmart_channel',
        'Shopmart Notifiche',
        channelDescription: 'Notifiche per prodotti in scadenza',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      debugPrint('✓ Notifica mostrata: $title');
    } catch (e) {
      debugPrint('❌ Errore mostra notifica: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'shopmart_channel',
        'Shopmart Notifiche',
        channelDescription: 'Notifiche per prodotti in scadenza',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          '✓ Notifica schedulata: $title per ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Errore scheduling notifica: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✓ Notifica $id cancellata');
    } catch (e) {
      debugPrint('❌ Errore cancellazione notifica: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✓ Tutte le notifiche cancellate');
    } catch (e) {
      debugPrint('❌ Errore cancellazione notifiche: $e');
    }
  }

  Future<void> scheduleExpiryNotifications({
    required List<InventoryItem> products,
    required int urgentDays,
    required int warningDays,
    required String token,
  }) async {
    try {
      // Cancella notifiche esistenti
      await cancelAllNotifications();

      final now = DateTime.now();
      int notificationId = 0;

      for (final product in products) {
        final expiryDate = product.expiryDate;
        final daysLeft = expiryDate.difference(now).inDays;

        // Prodotto già scaduto - ignora
        if (daysLeft < 0) continue;

        // Notifica urgente (es. 3 giorni)
        if (daysLeft <= urgentDays) {
          // Cerca ricette con questo prodotto
          final recipes =
              await _fetchRecipesForProduct(product.productName, token);
          final recipeText = recipes.isNotEmpty
              ? '\n\nRicette suggerite: ${recipes.take(2).map((r) => r['title']).join(', ')}'
              : '';

          await showNotification(
            id: notificationId++,
            title:
                '🚨 URGENTE: ${product.productName} scade tra $daysLeft giorni!',
            body: 'Usa subito questo prodotto prima che scada.$recipeText',
            payload: 'product:${product.id}',
          );
        }
        // Notifica di avviso (es. 7 giorni)
        else if (daysLeft <= warningDays) {
          // Schedula notifica per 2 giorni prima della scadenza urgente
          final notificationDate =
              expiryDate.subtract(Duration(days: urgentDays));

          if (notificationDate.isAfter(now)) {
            await scheduleNotification(
              id: notificationId++,
              title: '⚠️ ${product.productName} scade presto',
              body: 'Tra $daysLeft giorni. Pianifica di utilizzarlo!',
              scheduledDate: notificationDate,
              payload: 'product:${product.id}',
            );
          }
        }
      }

      debugPrint('✓ Schedulate $notificationId notifiche per scadenze');
    } catch (e) {
      debugPrint('❌ Errore scheduling notifiche scadenze: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecipesForProduct(
    String productName,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recipes/suggest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ingredients': [productName],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }

      return [];
    } catch (e) {
      debugPrint('❌ Errore fetch ricette per notifica: $e');
      return [];
    }
  }

  Future<void> scheduleDailyCheck({
    required int hour,
    required List<InventoryItem> products,
    required int urgentDays,
    required int warningDays,
    required String token,
  }) async {
    try {
      // Schedula controllo giornaliero alle ore specificate
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0);

      // Se l'ora è già passata oggi, schedula per domani
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Cancella il controllo giornaliero precedente
      await cancelNotification(999999);

      // Schedula nuovo controllo
      await scheduleNotification(
        id: 999999,
        title: '📦 Controllo magazzino',
        body: 'Verifica prodotti in scadenza',
        scheduledDate: scheduledDate,
        payload: 'daily_check',
      );

      debugPrint(
          '✓ Controllo giornaliero schedulato per ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Errore scheduling controllo giornaliero: $e');
    }
  }
}
