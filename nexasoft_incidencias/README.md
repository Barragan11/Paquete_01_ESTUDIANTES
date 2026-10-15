# NexaSoft - Mesa de incidencias (versión recibida)

Aplicación de entrenamiento para mantenimiento de un producto heredado. Los datos son **ficticios**. Esta versión debe arrancar y mostrar incidencias; hay comportamientos defectuosos reportados por el cliente y peticiones de cambio pendientes. NO es un producto de operación real.

## Primera instalación

Prerequisito: Flutter instalado y al menos un dispositivo habilitado. El repositorio incluye el código fuente, los recursos y la configuración de dependencias; las carpetas nativas se generan con el SDK de Flutter instalado en cada equipo.

En la carpeta del proyecto:

```bash
flutter create . --project-name nexasoft_incidencias --platforms android,web,windows
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 7357
```

Para Android: conectar un teléfono con depuración USB y usar `flutter devices` y `flutter run -d <id>`; para Windows: `flutter run -d windows` (si el equipo cuenta con herramientas de escritorio).

**No usar** `flutter create` en una carpeta distinta ni sustituir los archivos `lib/` o `assets/`. El comando genera las carpetas nativas que faltan.

Scripts alternativos: `preparar.ps1` (Windows PowerShell) o `preparar.sh` (Linux/macOS); ejecutan la misma configuración.

## Características visibles

- Lista y detalle de incidencias; la búsqueda no distingue mayúsculas y encuentra coincidencias en título y descripción.
- Filtros combinables de estado y prioridad junto con el texto, con botón para limpiar los tres criterios.
- Totales por estado calculados desde todos los registros actuales, sin depender de la búsqueda.
- Registro de incidencias con prioridad Baja, Media o Alta y almacenamiento local de los datos.
- Cambio de estado y prioridad desde la pantalla de detalle, guardado en el almacenamiento local del dispositivo.
- Los registros existentes sin prioridad se cargan como Media.
- Botón de reinicio de datos de demostración (ícono de flecha circular en la barra superior).

La app usa un JSON de ejemplo como datos iniciales; después almacena los registros localmente. **Cambiar el JSON incluido no equivale a actualizar registros ya creados en el almacenamiento del dispositivo.** La opción Restablecer demostración elimina los cambios locales y restaura la semilla; usarla solo cuando se requiera reiniciar pruebas.

## Trabajo

Los tickets, requisitos de aceptación, bitácora individual y protocolo de uso de IA están en el documento de práctica distribuido por el profesor.

No copiar el código a asistentes públicos sin permiso. Los datos actuales son ficticios, pero se simulan los controles de confidencialidad de una empresa real.

## Reiniciar la app en Chrome conservando los datos (BUG-001)

En PowerShell, dentro de `nexasoft_incidencias`, ejecuta `./iniciar_web.ps1`.
Abre **http://localhost:7357** manualmente en tu Chrome habitual, con el mismo
perfil y sin modo incógnito.
Para reiniciar, detén el servidor, cierra la pestaña, ejecuta el mismo comando
y vuelve a abrir exactamente esa dirección.

`shared_preferences` guarda los datos web en el almacenamiento del navegador,
separado por origen (protocolo, host y puerto) y por perfil. `flutter run -d chrome`
puede cambiar el puerto y usar un perfil temporal de depuración. En ese caso no
se lee el mismo almacenamiento: al no encontrar la clave, `AlmacenLocal.leer()`
carga el JSON inicial. Por eso volver a ver la semilla no demuestra por sí solo
que `cambiarEstado` no guardó. Fijar solo el puerto no evita cambiar de perfil.
No alternes `localhost` y `127.0.0.1` durante la prueba.

El botón de flecha circular **Restablecer demostración** borra expresamente los
cambios locales; no representa cerrar y abrir la app. Borrar los datos del sitio
también elimina los registros. Los cambios anteriores de otro origen/perfil no
se trasladan automáticamente a esta dirección.

En la versión original, `cambiarEstado` solo modificaba la lista en memoria y no llamaba a `datos.guardar`: esa era la causa de BUG-001 en el código. La versión actual espera el guardado. El problema de origen/perfil de Chrome explica por qué la prueba puede seguir mostrando la semilla incluso con ese guardado corregido.

## Criterio y evidencia de BUG-003

En la versión original, `cantidadPendientes` se calculaba al iniciar y no se actualizaba al cambiar un estado: el tablero reutilizaba un valor antiguo. Ahora `GestorIncidencias.contar(estado)` cuenta todos los registros cuyo estado coincide
con el solicitado. El tablero utiliza `incidencias`, no el resultado de `buscar`.
Al volver del detalle o de un registro nuevo, la pantalla se reconstruye usando
los datos actuales. El gestor publica el cambio en memoria después de completar
el guardado; si falla, mantiene los registros y los totales anteriores.

Prueba manual con la semilla (si ya tienes registros propios, anota tus totales
reales; no restablezcas datos que quieras conservar):

| Paso | Mismo ID / estado | Pendientes | En proceso | Resueltas | Total |
| --- | --- | ---: | ---: | ---: | ---: |
| Inicial | INC-101 / Pendiente | 5 | 2 | 3 | 10 |
| Cambiar desde el detalle y volver | INC-101 / Resuelta | 4 | 2 | 4 | 10 |
| Cerrar y abrir con la misma URL y perfil | INC-101 / Resuelta | 4 | 2 | 4 | 10 |
| Volver a Pendiente desde el detalle | INC-101 / Pendiente | 5 | 2 | 3 | 10 |
| Registrar una incidencia nueva | Anotar su ID / Pendiente | 6 | 2 | 3 | 11 |
| Reiniciar otra vez | Mismo ID nuevo / Pendiente | 6 | 2 | 3 | 11 |

Estos valores son los **resultados esperados**, no capturas de una ejecución.
Para la evidencia solicitada, captura el detalle con INC-101 antes/después y
tras reiniciar, y el tablero con el conteo manual de la lista en cada paso.
Comprueba que los otros nueve registros no cambian. Busca un título que reduzca
la lista: las tres cantidades del tablero deben seguir iguales.

Ejecuta `flutter test` para la regresión automatizada. La prueba con almacenamiento
en memoria comprueba ID, estados, creación y recuentos al crear otro gestor;
no sustituye la prueba manual de cierre de Chrome ni las capturas solicitadas.

Fuentes: [shared_preferences](https://pub.dev/packages/shared_preferences/versions/2.5.6)
y el lanzador Chrome del SDK instalado,
`packages/flutter_tools/lib/src/web/chrome.dart` (`_createUserDataDirectory`).
## Revisión de entrega contra la guía (15 de octubre de 2026)

| Ticket | Implementación | Verificación automatizada | Pendiente para cierre documental |
| --- | --- | --- | --- |
| BUG-001 | Guardado esperado antes de publicar estado y altas | Recarga desde almacenamiento simulado, mismo ID y otros registros sin cambios; fallos de escritura | Capturas del mismo ID antes/después y al cerrar y abrir la app real; alta conservada |
| BUG-002 | Título y descripción sin distinguir mayúsculas, consulta recortada | wifi, WiFi, túnel, espacios y consulta vacía | Evidencias antes/después y explicaci?n de la causa |
| BUG-003 | Totales calculados sobre todos los datos actuales | Cambios en ambos sentidos, alta, recarga y búsqueda sin afectar totales | Capturas y conteo manual antes/después y tras reiniciar |
| FEAT-001 | Prioridad al crear, en lista y detalle, editable y persistida; Media para antiguos | Alta, cambio a Baja, recarga y valores inválidos | Capturas de creación Alta, cambio y reinicio real |
| FEAT-002 | Texto AND estado AND prioridad; limpieza visible; mensaje sin resultados | Combinación de los tres, texto vacío con filtros, cero resultados y totales independientes | Prueba visual de combinación y limpieza en la app |

Las pruebas con almacenamiento simulado no demuestran por sí mismas la persistencia del navegador al cerrar completamente. Seguir el procedimiento de URL y perfil fijo descrito arriba. No confundir resultados esperados con evidencia obtenida.

### Lo que falta para entregar todo lo solicitado

- Bitácora Word individual de cada jornada con datos reales del alumno, tiempos, hipótesis, decisiones, pruebas, capturas incrustadas y uso de IA. La plantilla `Bitacora_Diaria_NexaSoft.docx` mencionada en la guía no está incluida en esta carpeta. No se han inventado jornadas ni evidencias previas.
- Evidencias originales de reproducción y posteriores por ticket; cada captura debe indicar ID, ticket, paso y fecha. Si no se conservaron las originales, documentar esa ausencia y reproducir en una copia de la versión inicial sin sobrescribir el trabajo actual.
- Registrar los commits concretos y las pruebas relacionadas en las bitácoras, y la revisión de otro integrante. En la revisión inicial solo había un commit (`0269d3e`); consultar `git log --oneline` para identificar los commits de la entrega.
- Completar el registro anterior con resultados manuales y referencias a las evidencias para cerrar los cinco tickets. El código implementado no implica cierre documental.
- Resumen final del equipo con resultados reales y riesgos: persistencia web dependiente del origen/perfil; falta de verificación manual de cierre y reapertura y de validaci?n en Android/Windows en esta revisión.

### Archivos para conservar

Conservar fuentes, assets, pruebas, dependencias y lockfile, carpetas de plataforma y scripts de preparación. `iniciar_web.ps1` proporciona el origen fijo necesario para las pruebas web. Las pruebas de fallos de guardado se integraron en `test/widget_test.dart` y se eliminó el archivo separado redundante. No se crearon archivos nuevos para este seguimiento.

Para empaquetar fuentes, excluir `build/`, `.dart_tool/`, cachés, configuración local e IDE; estas rutas están ignoradas por Git. No borrar `.git` si se entrega historial: la guía pide repositorio y el profesor puede solicitar un ZIP que lo incluya.
