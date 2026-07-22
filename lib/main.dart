import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'database/db_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId != null && notificationResponse.actionId!.startsWith('action_wallet_')) {
    final wallet = notificationResponse.actionId!.replaceAll('action_wallet_', '');
    final input = notificationResponse.input;
    if (input != null && input.isNotEmpty) {
      final amount = double.tryParse(input);
      if (amount != null && amount > 0) {
        final cards = await DbHelper.instance.readAllCards();
        Map<String, dynamic>? targetCard;
        for (var c in cards) {
          final linked = c['linkedWallets'] ?? '';
          if (linked.toString().contains(wallet)) {
            targetCard = c;
            break;
          }
        }

        if (targetCard != null) {
          final tx = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'amount': amount,
            'date': DateTime.now().toIso8601String(),
            'type': 'Gasto',
            'cardId': targetCard['id'].toString(),
            'walletUsed': wallet,
            'description': 'Gasto rápido ($wallet)'
          };
          
          await DbHelper.instance.createTransaction(tx);
          
          Map<String, dynamic> updatedCard = Map<String, dynamic>.from(targetCard);
          final isCredit = updatedCard['isCredit'] == 1 || updatedCard['isCredit'] == true;
          if (isCredit) {
             updatedCard['debt'] = (updatedCard['debt'] ?? 0.0) + amount;
          } else {
             updatedCard['balance'] = (updatedCard['balance'] ?? 0.0) - amount;
          }
          await DbHelper.instance.updateCard(updatedCard);
          
          // Opcional: Actualizar la notificación para confirmar éxito
          // pero requeriría reinicializar el plugin acá.
        }
      }
    }
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("No se encontró el archivo .env o hubo un error: $e");
  }

  runApp(const MyApp());

  // Inicializar Notificaciones en segundo plano para no congelar la pantalla de inicio
  NotificationService().init(notificationTapBackground).then((_) async {
    await NotificationService().requestPermissions();
    await NotificationService().showPersistentNotification();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonIA',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
