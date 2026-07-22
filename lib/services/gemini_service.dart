import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database/db_helper.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  void initialize() {
    // Solo para pre-validar, pero el modelo real se creará en startChatSession
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Warning: GEMINI_API_KEY not found in .env');
      return;
    }
  }

  Future<void> startChatSession(int chatId, List<Map<String, dynamic>> previousMessages) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API Key no está configurada.");
    }

    // Construir contexto financiero leyendo de SQLite
    final income = await DbHelper.instance.getMonthlyIncome();
    final cards = await DbHelper.instance.readAllCards();
    
    String contextPrompt = "Eres MonIA, un asistente financiero experto y empático. ";
    contextPrompt += "Tu objetivo es ayudar al usuario a gestionar sus finanzas basándote estrictamente en sus datos reales.\n\n";
    contextPrompt += "DATOS FINANCIEROS DEL USUARIO:\n";
    contextPrompt += "- Ingreso Mensual Neto: S/ $income\n";
    contextPrompt += "- Tarjetas Activas:\n";
    
    for (var card in cards) {
      final isCredit = card['isCredit'] == 1 || card['isCredit'] == true;
      final type = isCredit ? 'Crédito' : 'Débito';
      contextPrompt += "  * Tarjeta: ${card['name']} ($type) - Apodo: ${card['nickname'] ?? 'Sin apodo'}\n";
      if (isCredit) {
        final creditLimit = card['creditLimit'] ?? 0.0;
        final debt = card['debt'] ?? 0.0;
        final tea = card['tea'] ?? 0.0;
        final billingDate = card['billingDate'] ?? 1;
        contextPrompt += "    Límite Disponible: S/ $creditLimit | Deuda Actual (Consumido): S/ $debt\n";
        contextPrompt += "    Tasa Efectiva Anual (TEA): $tea% | Día de Corte: $billingDate de cada mes\n";
      } else {
        final balance = card['balance'] ?? 0.0;
        final trea = card['trea'] ?? 0.0;
        final maintenance = card['maintenance'] ?? 0.0;
        final linked = card['linkedWallets'] ?? 'Ninguna';
        contextPrompt += "    Saldo Disponible: S/ $balance\n";
        contextPrompt += "    Billeteras Vinculadas (Yape/Plin): $linked\n";
        contextPrompt += "    Tasa de Rendimiento (TREA): $trea% | Comisión de Mantenimiento: S/ $maintenance\n";
      }
    }
    
    contextPrompt += "\nREGLAS:\n";
    contextPrompt += "1. Sé directo y conciso. No hagas respuestas gigantes.\n";
    contextPrompt += "2. Si el usuario quiere comprar algo, calcula si tiene saldo suficiente en sus cuentas de débito o límite en crédito. Aconséjalo matemáticamente.\n";
    contextPrompt += "3. Responde siempre en español, con un tono amable y motivador.\n";

    // Crear el modelo con las instrucciones del sistema
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(contextPrompt),
    );

    // Reconstruir historial para Gemini (Garantizando alternancia Estricta User -> Model)
    List<Content> history = [];
    String? lastRole;

    for (var msg in previousMessages) {
      final isUser = msg['isUser'] == 1 || msg['isUser'] == true;
      final text = (msg['text'] ?? '').toString();
      if (text.trim().isEmpty) continue;
      
      final currentRole = isUser ? 'user' : 'model';
      if (currentRole == lastRole) continue; // Evitar mensajes consecutivos del mismo rol

      if (isUser) {
        history.add(Content.text(text));
      } else {
        history.add(Content.model([TextPart(text)]));
      }
      lastRole = currentRole;
    }

    _chatSession = _model!.startChat(history: history);
  }

  Stream<String> sendMessageStream(String text) async* {
    if (_chatSession == null) {
      throw Exception("Debes iniciar la sesión de chat primero.");
    }
    try {
      final responseStream = _chatSession!.sendMessageStream(Content.text(text));
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "Hubo un error de conexión con MonIA: $e";
    }
  }
}
