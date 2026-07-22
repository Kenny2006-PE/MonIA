import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/db_helper.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(void Function(NotificationResponse) onBackgroundHandler) async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveBackgroundNotificationResponse: onBackgroundHandler,
      onDidReceiveNotificationResponse: (details) {
         // Cuando se toca estando en foreground o para abrir la app.
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  Future<void> showPersistentNotification() async {
    // 1. Obtener billeteras vinculadas
    final cards = await DbHelper.instance.readAllCards();
    List<String> activeWallets = [];
    
    for (var card in cards) {
      final linkedStr = card['linkedWallets'] ?? '';
      if (linkedStr.toString().isNotEmpty) {
        final wallets = linkedStr.toString().split(',');
        for (var w in wallets) {
          if (!activeWallets.contains(w) && w.isNotEmpty) {
            activeWallets.add(w);
          }
        }
      }
    }

    // Si no hay billeteras, tal vez poner la primera tarjeta débito
    if (activeWallets.isEmpty && cards.isNotEmpty) {
      // Opcional, pero para este caso nos enfocamos en las billeteras como pidió el usuario.
    }

    List<AndroidNotificationAction> actions = [];
    
    for (var wallet in activeWallets) {
      actions.add(
        AndroidNotificationAction(
          'action_wallet_$wallet',
          'Registrar en $wallet',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Ej: 15.50',
              allowFreeFormInput: true,
            ),
          ],
        ),
      );
    }

    // 2. Construir la notificación
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'quick_expense_channel',
      'Conteo Rápido',
      channelDescription: 'Canal para registrar gastos rápidamente',
      importance: Importance.low, // low para que no suene cada vez, pero se mantenga ahí
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Asistente Financiero',
      body: activeWallets.isEmpty ? 'Añade una billetera vinculada para registrar gastos' : '¿Hiciste algún gasto?',
      notificationDetails: platformChannelSpecifics,
    );
  }
}
