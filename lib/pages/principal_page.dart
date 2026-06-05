import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/lugares_pages.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:inventarioss/pages/inventario_page.dart';
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/api_config.dart'; // Tu import original e intocable

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static bool _tutorialMostrado = false;

  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado;

  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  late final ValueNotifier<List<Map<String, dynamic>>> _eventosDelDiaSeleccionado;
  bool _estaCargando = false; 

  // Variable de control para el texto de búsqueda
  String _filtroTexto = '';

  final Color colorInstitucional = const Color(0xFF1A426E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _diaSeleccionado = _diaEnfocado;
    _eventosDelDiaSeleccionado = ValueNotifier([]);
    
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _eventosDelDiaSeleccionado.dispose();
    super.dispose();
  }

  // =====================================================================
  // ACCIONES DE ADMINISTRADOR (PUT / POST CON BACKEND)
  // =====================================================================
  Future<void> _cambiarEstatusSolicitud(int idSolicitud, int nuevoEstatus) async {
  // 1. Determinar la ruta y el body exacto según lo que pide tu backend
  String path = '';
  Map<String, dynamic> body = {};

  switch (nuevoEstatus) {
    case 1: // AUTORIZAR
      path = '/api/solicitudes/autorizar/$idSolicitud';
      body = {'id_autoriza': 1}; // El ID del admin que autoriza
      break;
      
    case 2: // RECHAZAR (Ajusta la ruta si en tu backend cambia)
      path = '/api/solicitudes/rechazar/$idSolicitud';
      body = {'id_rechaza': 1}; 
      break;
      
    case 3: 
      path = '/api/solicitudes/recibir/$idSolicitud'; // Ruta corregida
      body = {
        'id_recibe': 1, 
        'hora_fecha_real_conclusion': DateTime.now().toIso8601String(), // Hora del sistema agregada
      };
      break;
      
    default:
      return;
  }

  final url = Uri.parse('${ApiConfig.baseUrl}$path');

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      
      // Decodificamos el mensaje calientito que manda tu backend
      final respuestaJson = json.decode(response.body);
      String mensajeServidor = respuestaJson['mensaje'] ?? 'Estatus actualizado con éxito';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeServidor), backgroundColor: Colors.green),
      );
      
      _cargarSolicitudes(); // Recarga el calendario
    } else {
      // Si el backend manda un error de validación (ej. usuario no existe) lo atrapamos aquí
      final respuestaJson = json.decode(response.body);
      throw Exception(respuestaJson['mensaje'] ?? 'Error en el servidor');
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
    );
  }
}

  // =====================================================================
  // GET - PROCESAMIENTO CORRECTO DE TU JSON (CORREGIDO PARA DESPLIEGUE)
  // =====================================================================
  Future<void> _cargarSolicitudes() async {
    setState(() {
      _estaCargando = true;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/api/solicitudes'); 

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> respuestaJson = json.decode(response.body);
        final List<dynamic> listaSolicitudes = respuestaJson['datos'] ?? [];
        
        Map<DateTime, List<Map<String, dynamic>>> eventosCargados = {};

        for (var solicitud in listaSolicitudes) {
          if (solicitud['hora_fecha_inicio_solicitada'] == null) continue;

          String fechaRaw = solicitud['hora_fecha_inicio_solicitada'].toString();
          if (fechaRaw.endsWith('Z')) {
            fechaRaw = fechaRaw.substring(0, fechaRaw.length - 1);
          }

          DateTime fechaInicio = DateTime.parse(fechaRaw).toLocal();
          DateTime fechaNormalizada = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

          if (eventosCargados[fechaNormalizada] == null) {
            eventosCargados[fechaNormalizada] = [];
          }
          eventosCargados[fechaNormalizada]!.add(solicitud);
        }

        setState(() {
          _eventos = eventosCargados;
          _estaCargando = false;
        });

        _eventosDelDiaSeleccionado.value = _obtenerEventosParaDia(_diaSeleccionado!);

      } else {
        throw Exception('Error en respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión con Azure Backend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _obtenerEventosParaDia(DateTime dia) {
    final diaNormalized = DateTime(dia.year, dia.month, dia.day);
    return _eventos[diaNormalized] ?? [];
  }

  void _alSeleccionarDia(DateTime diaSeleccionado, DateTime diaEnfocado) {
    if (!isSameDay(_diaSeleccionado, diaSeleccionado)) {
      setState(() {
        _diaSeleccionado = diaSeleccionado;
        _diaEnfocado = diaEnfocado;
        _filtroTexto = ''; 
      });
      _eventosDelDiaSeleccionado.value = _obtenerEventosParaDia(diaSeleccionado);
    }
  }

  String _extraerHoraDeIso(String isoString) {
    try {
      String filtrada = isoString;
      if (filtrada.endsWith('Z')) {
        filtrada = filtrada.substring(0, filtrada.length - 1);
      }
      DateTime dateTime = DateTime.parse(filtrada).toLocal();
      String hora = dateTime.hour.toString().padLeft(2, '0');
      String minuto = dateTime.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    } catch (_) {
      return '00:00';
    }
  }

  String _obtenerTextoEstatus(int estatus) {
    switch (estatus) {
      case 1: return 'APROBADA';
      case 2: return 'RECHAZADA';
      case 3: return 'FINALIZADA';
      default: return 'EN ESPERA';
    }
  }

  Color _obtenerColorEstatus(int estatus) {
    switch (estatus) {
      case 1: return Colors.green;
      case 2: return Colors.red;
      case 3: return Colors.grey;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: colorInstitucional,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Agenda Principal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.menu, size: 28), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorInstitucional),
              child: const Center(child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24))),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Solicitantes'),
              onTap: () => Navigator.pushReplacement(context, TransicionElegante(page: const SolicitantesPage())),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventario'),
              onTap: () => Navigator.pushReplacement(context, TransicionElegante(page: const InventarioPage())),
            ),
          ],
        ),
      ), 
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _diaEnfocado,
              selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
              calendarFormat: _formatoCalendario,
              eventLoader: _obtenerEventosParaDia,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: colorInstitucional.withOpacity(0.4), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: colorInstitucional, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              onDaySelected: _alSeleccionarDia,
              onPageChanged: (focusedDay) => _diaEnfocado = focusedDay,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _filtroTexto = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por ID o Solicitante...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: colorInstitucional, size: 22),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorInstitucional, width: 1.5),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _estaCargando 
              ? Center(child: CircularProgressIndicator(color: colorInstitucional))
              : ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _eventosDelDiaSeleccionado,
                  builder: (context, solicitudesDia, _) {
                    if (solicitudesDia.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text('Sin solicitudes para este día', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }

                    final solicitudesFiltradas = solicitudesDia.where((item) {
                      final id = (item['id_solicitud'] ?? '').toString().toLowerCase();
                      final nombre = (item['nombre_completo_solicitante'] ?? '').toString().toLowerCase();
                      return id.contains(_filtroTexto) || nombre.contains(_filtroTexto);
                    }).toList();

                    if (solicitudesFiltradas.isEmpty && _filtroTexto.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 45, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text('Ningún registro coincide con la búsqueda', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _cargarSolicitudes,
                      color: colorInstitucional,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: solicitudesFiltradas.length,
                        itemBuilder: (context, index) {
                          final item = solicitudesFiltradas[index];
                          
                          int idSolicitud = item['id_solicitud'] ?? 0;
                          int estatus = item['estatus'] ?? 0;
                          String horaInicio = _extraerHoraDeIso(item['hora_fecha_inicio_solicitada'] ?? '');
                          String horaFin = _extraerHoraDeIso(item['hora_fecha_conclusion_solicitada'] ?? '');
                          String motivo = item['Motivo'] ?? 'Sin motivo registrado';
                          String solicitante = item['nombre_completo_solicitante'] ?? 'Anónimo';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: colorInstitucional.withOpacity(0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.assignment, color: colorInstitucional),
                                    ),
                                    title: Text(
                                      '$horaInicio - $horaFin | $motivo', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Solicita: $solicitante', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Estatus: ${_obtenerTextoEstatus(estatus)}', 
                                            style: TextStyle(color: _obtenerColorEstatus(estatus), fontWeight: FontWeight.bold, fontSize: 11)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (estatus == 0 || estatus == 1) ...[
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (estatus == 0) ...[
                                          TextButton.icon(
                                            onPressed: () => _cambiarEstatusSolicitud(idSolicitud, 2), 
                                            icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                            label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                            onPressed: () => _cambiarEstatusSolicitud(idSolicitud, 1), 
                                            icon: const Icon(Icons.check, size: 18),
                                            label: const Text('Aprobar'),
                                          ),
                                        ],
                                        if (estatus == 1) ...[
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: colorInstitucional, foregroundColor: Colors.white),
                                            onPressed: () => _cambiarEstatusSolicitud(idSolicitud, 3), 
                                            icon: const Icon(Icons.assignment_returned, size: 18),
                                            label: const Text('Marcar Devolución'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}