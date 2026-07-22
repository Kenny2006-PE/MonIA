# 🤖 MonIA - Asistente Financiero Inteligente

**MonIA** es una aplicación móvil desarrollada en **Flutter** diseñada para simplificar el control financiero personal. Combina el poder de la Inteligencia Artificial de Google (Gemini) con herramientas de registro ultra rápido para ayudarte a tomar mejores decisiones sobre tu dinero.

---

## ✨ Características Principales

- 💡 **Asistente IA (MonIA):** Asesoramiento financiero personalizado en tiempo real basado estrictamente en tus datos reales, ingresos, tarjetas y deudas.
- ⚡ **Registro Rápido por Notificaciones:** Registra tus gastos del día a día (Yape, Plin, efectivo) respondiendo directamente desde la barra de notificaciones de Android sin necesidad de abrir la aplicación.
- 💳 **Gestión de Tarjetas y Billeteras:** Soporte para tarjetas de Crédito (TEA, Fechas de Corte, Deudas) y Débito (TREA, Comisiones), vinculadas a billeteras virtuales como **Yape** y **Plin**.
- 📊 **Historial y Resumen de Movimientos:** Control total de tus ingresos y gastos en tiempo real con actualización automática de saldos.
- 🔒 **Privacidad y Velocidad (Offline First):** Almacenamiento local mediante **SQLite** para un rendimiento instantáneo y seguro.
- 🎨 **Diseño Moderno & Ultra Fluido:** Interfaz en modo oscuro (*Dark Mode*) con animaciones fluidas y micro-interacciones.

---

## 🛠️ Tecnologías Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **IA Engine:** [Google Generative AI SDK (Gemini 3.5 Flash)](https://pub.dev/packages/google_generative_ai)
- **Base de Datos Local:** [SQLite (sqflite)](https://pub.dev/packages/sqflite)
- **Notificaciones Nativas:** [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Animaciones:** [Flutter Animate](https://pub.dev/packages/flutter_animate)

---

## 🚀 Instalación y Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/Kenny2006-PE/MonIA.git
   cd MonIA
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configurar la API Key de Gemini:**
   Crea un archivo `.env` en la raíz del proyecto y agrega tu llave:
   ```env
   GEMINI_API_KEY=tu_api_key_aqui
   ```

4. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

---

Desarrollado con ❤️ usando Flutter e Inteligencia Artificial.
