import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos;
  List<Incidencia> incidencias = [];

  GestorIncidencias({AlmacenLocal? datos}) : datos = datos ?? AlmacenLocal();

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  List<Incidencia> buscar(String texto,
      {String estado = 'Todos', String prioridad = 'Todas'}) {
    final consulta = texto.trim().toLowerCase();
    return incidencias
        .where((x) =>
            (estado == 'Todos' || x.estado == estado) &&
            (prioridad == 'Todas' || x.prioridad == prioridad) &&
            (x.titulo.toLowerCase().contains(consulta) ||
                x.descripcion.toLowerCase().contains(consulta)))
        .toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        final actualizadas = List<Incidencia>.of(incidencias);
        actualizadas[i] = Incidencia.desdeJson({
          ...incidencias[i].toJson(),
          'estado': estado,
        });
        await datos.guardar(actualizadas);
        incidencias = actualizadas;
        break;
      }
    }
  }

  Future<void> cambiarPrioridad(String id, String prioridad) async {
    if (!Incidencia.prioridadValida(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Prioridad inválida');
    }
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        final actualizadas = List<Incidencia>.of(incidencias);
        actualizadas[i] = Incidencia.desdeJson({
          ...incidencias[i].toJson(),
          'prioridad': prioridad,
        });
        await datos.guardar(actualizadas);
        incidencias = actualizadas;
        break;
      }
    }
  }

  Future<void> crear(
      String titulo, String descripcion, String cliente, String categoria,
      {String prioridad = 'Media'}) async {
    if (!Incidencia.prioridadValida(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Prioridad inválida');
    }
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
      prioridad: prioridad,
    );
    final actualizadas = [nuevo, ...incidencias];
    await datos.guardar(actualizadas);
    incidencias = actualizadas;
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
