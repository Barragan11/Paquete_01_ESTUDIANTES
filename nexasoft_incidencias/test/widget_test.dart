import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

void main() {
  test('Una incidencia antigua puede convertirse desde JSON', () {
    final registro = Incidencia.desdeJson({
      'id': 'INC-DEMO',
      'titulo': 'Prueba',
      'descripcion': 'Caso de ejemplo',
      'cliente': 'Cliente ficticio',
      'categoria': 'Redes',
      'estado': 'Pendiente',
      'fecha': '2026-10-12',
    });
    expect(registro.id, 'INC-DEMO');
    expect(registro.toJson()['estado'], 'Pendiente');
    expect(registro.prioridad, 'Media');
    expect(registro.toJson()['prioridad'], 'Media');
  });

  test('Los estados y totales se conservan y no dependen de la búsqueda',
      () async {
    final almacen = _AlmacenEnMemoria();
    final iniciales = [
      {
        'id': 'INC-101',
        'titulo': 'Impresora',
        'descripcion': 'No responde',
        'cliente': 'Cliente A',
        'categoria': 'Hardware',
        'estado': 'Pendiente',
        'fecha': '2026-10-12',
      },
      {
        'id': 'INC-102',
        'titulo': 'WiFi',
        'descripcion': 'Intermitente',
        'cliente': 'Cliente B',
        'categoria': 'Redes',
        'estado': 'En proceso',
        'fecha': '2026-10-12',
      },
    ];
    await almacen.guardar(
      iniciales.map((registro) => Incidencia.desdeJson(registro)).toList(),
    );

    final gestor = GestorIncidencias(datos: almacen);
    await gestor.iniciar();
    expect(gestor.porId('INC-101')!.estado, 'Pendiente');

    await gestor.cambiarEstado('INC-101', 'Resuelta');
    expect(gestor.porId('INC-101')!.estado, 'Resuelta');
    expect(gestor.porId('INC-102')!.estado, 'En proceso');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 1);

    gestor.buscar('WiFi');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 1);

    await gestor.cambiarEstado('INC-101', 'Pendiente');
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 0);

    await gestor.cambiarEstado('INC-101', 'Resuelta');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 1);

    await gestor.crear('Nueva', 'Descripción', 'Cliente C', 'Software');
    final nueva = gestor.incidencias.first;
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 1);

    final gestorTrasReinicio = GestorIncidencias(datos: almacen);
    await gestorTrasReinicio.iniciar();
    expect(gestorTrasReinicio.porId('INC-101')!.estado, 'Resuelta');
    expect(gestorTrasReinicio.porId('INC-102')!.estado, 'En proceso');
    expect(gestorTrasReinicio.porId(nueva.id)!.titulo, 'Nueva');
    expect(gestorTrasReinicio.contar('Pendiente'), 1);
    expect(gestorTrasReinicio.contar('En proceso'), 1);
    expect(gestorTrasReinicio.contar('Resuelta'), 1);
  });

  test('La búsqueda encuentra título y descripción sin distinguir mayúsculas',
      () async {
    final almacen = _AlmacenEnMemoria();
    await almacen.guardar([
      Incidencia.desdeJson({
        'id': 'INC-WIFI',
        'titulo': 'WiFi intermitente en recepción',
        'descripcion': 'La red se desconecta.',
        'cliente': 'Cliente A',
        'categoria': 'Redes',
        'estado': 'Pendiente',
        'fecha': '2026-10-12',
      }),
      Incidencia.desdeJson({
        'id': 'INC-VPN',
        'titulo': 'Configuración de VPN',
        'descripcion': 'No se establece el túnel seguro.',
        'cliente': 'Cliente B',
        'categoria': 'Redes',
        'estado': 'En proceso',
        'fecha': '2026-10-12',
      }),
    ]);
    final gestor = GestorIncidencias(datos: almacen);
    await gestor.iniciar();

    expect(gestor.buscar('wifi').map((x) => x.id), ['INC-WIFI']);
    expect(gestor.buscar('WiFi').map((x) => x.id), ['INC-WIFI']);
    expect(gestor.buscar('túnel').map((x) => x.id), ['INC-VPN']);
    expect(gestor.buscar('  WiFi  ').map((x) => x.id), ['INC-WIFI']);
    expect(gestor.buscar('   ').length, 2);
  });

  test('La prioridad se valida y persiste al reiniciar el gestor', () async {
    final almacen = _AlmacenEnMemoria();
    final gestor = GestorIncidencias(datos: almacen);
    await gestor.iniciar();

    await gestor.crear(
      'Incidencia urgente',
      'Descripción',
      'Cliente',
      'Redes',
      prioridad: 'Alta',
    );
    final nueva = gestor.incidencias.first;
    expect(nueva.prioridad, 'Alta');

    await gestor.cambiarPrioridad(nueva.id, 'Baja');
    expect(gestor.porId(nueva.id)!.prioridad, 'Baja');
    await expectLater(
      gestor.cambiarPrioridad(nueva.id, 'Crítica'),
      throwsArgumentError,
    );

    final gestorTrasReinicio = GestorIncidencias(datos: almacen);
    await gestorTrasReinicio.iniciar();
    expect(gestorTrasReinicio.porId(nueva.id)!.prioridad, 'Baja');
  });

  test('Texto, estado y prioridad se combinan sin alterar los totales',
      () async {
    final gestor = GestorIncidencias(datos: _AlmacenEnMemoria());
    await gestor.iniciar();
    await gestor.crear('WiFi', 'Recepción', 'A', 'Redes', prioridad: 'Alta');
    final idAlta = gestor.incidencias.first.id;
    await gestor.crear('WiFi', 'Oficina', 'B', 'Redes', prioridad: 'Baja');
    await gestor.crear('VPN', 'Túnel WiFi', 'C', 'Redes', prioridad: 'Alta');
    await gestor.cambiarEstado(gestor.incidencias.first.id, 'Resuelta');

    expect(
        gestor
            .buscar(' wifi ', estado: 'Pendiente', prioridad: 'Alta')
            .map((x) => x.id),
        [idAlta]);
    expect(
        gestor
            .buscar('', estado: 'Pendiente', prioridad: 'Alta')
            .map((x) => x.id),
        [idAlta]);
    expect(gestor.buscar('WiFi', estado: 'En proceso', prioridad: 'Alta'),
        isEmpty);
    expect(gestor.buscar('', prioridad: 'Baja').length, 1);
    expect(gestor.buscar('').length, 3);
    expect(gestor.contar('Pendiente'), 2);
    expect(gestor.contar('Resuelta'), 1);
  });

  test('Un fallo de guardado conserva el estado y los totales anteriores',
      () async {
    final gestor = GestorIncidencias(datos: _AlmacenQueFalla());
    await gestor.iniciar();
    final anterior = gestor.porId('INC-101')!.toJson();
    await expectLater(
      gestor.cambiarEstado('INC-101', 'Resuelta'),
      throwsStateError,
    );
    expect(gestor.porId('INC-101')!.toJson(), anterior);
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('Resuelta'), 0);
  });

  test('Un alta no guardada no aparece en la lista ni en el tablero', () async {
    final gestor = GestorIncidencias(datos: _AlmacenQueFalla());
    await gestor.iniciar();
    await expectLater(
      gestor.crear('Nueva', 'Reporte', 'Cliente', 'Software'),
      throwsStateError,
    );
    expect(gestor.incidencias.map((x) => x.id), ['INC-101']);
    expect(gestor.contar('Pendiente'), 1);
  });

  test('Una prioridad antigua o no aprobada utiliza Media', () {
    final registroAntiguo = Incidencia.desdeJson({
      'id': 'INC-ANTIGUA',
      'prioridad': 'Crítica',
    });
    expect(registroAntiguo.prioridad, 'Media');
    registroAntiguo.prioridad = 'Crítica';
    expect(registroAntiguo.prioridad, 'Media');
  });
}

class _AlmacenEnMemoria extends AlmacenLocal {
  String? contenido;

  @override
  Future<List<Incidencia>> leer() async {
    if (contenido == null) return [];
    final lista = jsonDecode(contenido!) as List<dynamic>;
    return lista
        .map((item) => Incidencia.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> guardar(List<Incidencia> lista) async {
    contenido =
        jsonEncode(lista.map((incidencia) => incidencia.toJson()).toList());
  }
}

class _AlmacenQueFalla extends AlmacenLocal {
  @override
  Future<List<Incidencia>> leer() async => [
        Incidencia(
          id: 'INC-101',
          titulo: 'Prueba',
          descripcion: 'Reporte',
          cliente: 'Cliente',
          categoria: 'Software',
          estado: 'Pendiente',
          fecha: '2026-10-13',
        ),
      ];

  @override
  Future<void> guardar(List<Incidencia> lista) async {
    throw StateError('Almacenamiento no disponible');
  }
}
