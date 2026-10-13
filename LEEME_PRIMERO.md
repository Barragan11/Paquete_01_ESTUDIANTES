PRÁCTICA 01 - NEXASOFT SOLUTIONS
================================

ARCHIVOS PARA ENTREGAR A LOS ESTUDIANTES
- Paquete_01_ESTUDIANTES.zip contiene:
  * Proyecto Flutter (FUENTES; las carpetas nativas se generan localmente)
  * Guía PDF y código LaTeX editable (.tex)
  * Bitácora Word (.docx)
- Proyecto_NexaSoft_Flutter.zip: únicamente el código fuente Flutter.

DOCENTE (RESERVADO)
- Paquete_01_DOCENTE_RESERVADO.zip: incluye lo anterior más la guía
  reservada, donde se indican los errores intencionales y casos de prueba.
  No entregar ese ZIP a los estudiantes.

ARRANQUE DEL PROYECTO
1. Extrae proyecto en una carpeta.
2. Desde la raíz ejecuta:
   flutter create . --project-name nexasoft_incidencias --platforms android,web,windows
   flutter pub get
   flutter run -d chrome
3. Si se ejecuta en Android usar ID de flutter devices en lugar de chrome.

VALIDACIÓN Y ALCANCE
- Verificados: integridad de JSON, conteo inicial, dependencias y rutas locales,
  compilación de LaTeX y renderizado de Word.
- No hay Flutter SDK disponible en el entorno de generación, por lo que NO
  se ejecutaron flutter analyze, flutter test ni flutter run. Se recomienda
  ejecutarlos en un equipo con Flutter antes de repartir la práctica.
- Simula datos confidenciales, pero todos los datos incluidos son ficticios.
