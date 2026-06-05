import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventarioss/pages/miperfil_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN Y CONFIGURACIÓN
// =====================================================================
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; 
import 'package:inventarioss/api_config.dart'; 

class Principal_user_Page extends StatefulWidget {
  const Principal_user_Page({super.key});

  @override
  State<Principal_user_Page> createState() => _PrincipalUserPageState();
}

class _PrincipalUserPageState extends State<Principal_user_Page> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static bool _tutorialMostrado = false;

  // Variables de estado para el calendario
  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado;

  // ===> CORRECCIÓN DE TIPO: Cambiado a List<dynamic> para integrarse sin romper con TableCalendar <===
  late Map<DateTime, List<dynamic>> _eventos;
  late final ValueNotifier<List<dynamic>> _eventosDelDiaSeleccionado;
  bool _cargandoSolicitudes = false;

  final Color colorInstitucional = const Color(0xFF1A426E);
  int _idUsuario = 0;

  final List<String> _inventarioNombres = [
    'Laptop Dell XPS', 'MacBook Air M2', 'Proyector Epson U50',
    'Cámara Canon T7i', 'Trípode Manfrotto', 'Micrófono Shure SM58',
    'Kit Iluminación LED', 'Cable HDMI 10m', 'Bocina Bluetooth JBL',
  ];

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _diaSeleccionado = _diaEnfocado;
    _eventos = {};
    _eventosDelDiaSeleccionado = ValueNotifier([]);

    // Disparamos la carga de datos secuencial
    _inicializarDatos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tutorialMostrado) {
        _mostrarTutorialNavegacion();
      }
    });
  }

  // Encargado de orquestar la carga de preferencias y de inmediato traer datos de la red
  Future<void> _inicializarDatos() async {
    await _cargarDatosUsuario();
    await _obtenerSolicitudesBackend();
  }

  // Recupera el ID desde memoria SharedPreferences
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idUsuario = prefs.getInt('id_usuario') ?? 0;
    });
    print('------------------------------------------------------------');
    print('👤 SESIÓN INSTANCIADA -> ID del Solicitante: $_idUsuario');
    print('------------------------------------------------------------');
  }

  // =====================================================================
  // METODO NUEVO: GET CONEXIÓN REAL CON BACKEND EN AZURE
  // =====================================================================
  Future<void> _obtenerSolicitudesBackend() async {
    setState(() => _cargandoSolicitudes = true);
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/solicitudes');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> respuestaJson = jsonDecode(response.body);
        if (respuestaJson['error'] == false) {
          final List<dynamic> listaSolicitudes = respuestaJson['datos'];

          // ===> CORRECCIÓN: Mapeo temporal compatible con la respuesta dynamic de la API <===
          Map<DateTime, List<dynamic>> nuevoMapaEventos = {};

          for (var item in listaSolicitudes) {
            if (item['hora_fecha_inicio_solicitada'] != null) {
              // Parseamos el string ISO UTC (ej: 2026-06-05T09:00:00.000Z)
              DateTime fechaCompleta = DateTime.parse(item['hora_fecha_inicio_solicitada']).toLocal();
              // Normalizamos quitando horas para agruparlo exactamente en su celda del calendario
              DateTime fechaCelda = DateTime(fechaCompleta.year, fechaCompleta.month, fechaCompleta.day);

              if (nuevoMapaEventos[fechaCelda] == null) {
                nuevoMapaEventos[fechaCelda] = [];
              }
              nuevoMapaEventos[fechaCelda]!.add(item);
            }
          }

          setState(() {
            _eventos = nuevoMapaEventos;
          });
          // Forzamos actualización de la lista inferior de actividades basándonos en el día actual
          _actualizarEventosDelDia(_diaSeleccionado!);
        }
      }
    } catch (e) {
      print("❌ Error cargando solicitudes de la base de datos: $e");
    } finally {
      setState(() => _cargandoSolicitudes = false);
    }
  }

  void _actualizarEventosDelDia(DateTime dia) {
    final diaNormalizado = DateTime(dia.year, dia.month, dia.day);
    _eventosDelDiaSeleccionado.value = _eventos[diaNormalizado] ?? [];
  }

  // Mapeador estricto para TableCalendar
  List<dynamic> _obtenerEventosParaDia(DateTime dia) {
    final diaNormalizado = DateTime(dia.year, dia.month, dia.day);
    return _eventos[diaNormalizado] ?? [];
  }

  void _alSeleccionarDia(DateTime diaSeleccionado, DateTime diaEnfocado) {
    if (!isSameDay(_diaSeleccionado, diaSeleccionado)) {
      setState(() {
        _diaSeleccionado = diaSeleccionado;
        _diaEnfocado = diaEnfocado;
      });
      _actualizarEventosDelDia(diaSeleccionado);
    }
  }

  // =====================================================================
  // HELPERS DE DISEÑO PARA ESTADOS (0, 1, 2, 3)
  // =====================================================================
  Color _obtenerColorEstado(int estatus) {
    switch (estatus) {
      case 1:  return const Color(0xFF0A3161); // Navy Aprobada
      case 2:  return Colors.redAccent;        // Rojo Rechazada
      case 3:  return Colors.teal;             // Verde azulado Devuelta/Finalizada
      case 0:
      default: return Colors.orangeAccent;     // Naranja Espera
    }
  }

  String _obtenerTextoEstado(int estatus) {
    switch (estatus) {
      case 1:  return 'APROBADA';
      case 2:  return 'RECHAZADA';
      case 3:  return 'FINALIZADA';
      case 0:
      default: return 'EN ESPERA';
    }
  }

  IconData _obtenerIconoEstado(int estatus) {
    switch (estatus) {
      case 1:  return Icons.check_circle_outline_rounded;
      case 2:  return Icons.cancel_outlined;
      case 3:  return Icons.assignment_turned_in_outlined;
      case 0:
      default: return Icons.hourglass_empty_rounded;
    }
  }

  String _extraerHoraDeString(String? fechaIso) {
    if (fechaIso == null) return "00:00";
    try {
      DateTime dt = DateTime.parse(fechaIso).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "00:00";
    }
  }

  // =====================================================================
  // DESPLIEGUE DEL FORMULARIO Y CONEXIÓN ESTRICTA AL BACKEND
  // =====================================================================
  void _mostrarFormularioReservacion() {
    final formKey = GlobalKey<FormState>();
    TextEditingController motivoController = TextEditingController();
    
    TimeOfDay? horaInicio;
    TimeOfDay? horaEntrega;
    String? garantiaSeleccionada;
    String? equipoSeleccionado; 

    String formatearHora(TimeOfDay? time) {
      if (time == null) return 'Seleccionar';
      final hora = time.hour.toString().padLeft(2, '0');
      final minuto = time.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                left: 24, right: 24, top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nueva Reservación',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorInstitucional),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _BotonHora(
                              titulo: 'Inicio',
                              valor: formatearHora(horaInicio),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setModalState(() => horaInicio = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _BotonHora(
                              titulo: 'Entrega (Aprox)',
                              valor: formatearHora(horaEntrega),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setModalState(() => horaEntrega = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (horaInicio == null || horaEntrega == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Ambas horas son obligatorias*', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: equipoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Equipo Solicitado',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.devices),
                        ),
                        items: _inventarioNombres.map((String equipo) {
                          return DropdownMenuItem<String>(
                            value: equipo,
                            child: Text(equipo, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => equipoSeleccionado = val);
                        },
                        validator: (value) => value == null ? 'Por favor seleccione un equipo' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: garantiaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Garantía Física',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        items: ['Credencial Estudiante', 'Credencial Docente', 'INE']
                            .map((String val) => DropdownMenuItem(value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) {
                          setModalState(() => garantiaSeleccionada = val);
                        },
                        validator: (value) => value == null ? 'Seleccione una garantía' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: motivoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Motivo de uso',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) => value!.isEmpty ? 'El motivo es requerido por el servidor' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorInstitucional,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate() && horaInicio != null && horaEntrega != null) {
                            
                            if (_idUsuario == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: El ID de usuario es 0. Vuelve a iniciar sesión.'), 
                                  backgroundColor: Colors.orange
                                ),
                              );
                              return; 
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(color: Color(0xFF1A426E)),
                              ),
                            );

                            final String horaInicioStr = formatearHora(horaInicio);
                            final String horaEntregaStr = formatearHora(horaEntrega);
                            
                            final String fechaBase = "${_diaSeleccionado!.year}-${_diaSeleccionado!.month.toString().padLeft(2, '0')}-${_diaSeleccionado!.day.toString().padLeft(2, '0')}";
                            final String horaFechaInicio = "$fechaBase $horaInicioStr:00";
                            final String horaFechaFin = "$fechaBase $horaEntregaStr:00";

                            // ===> CORRECCIÓN: 'notes' cambiado por 'notas' para emparejar con tu Base de Datos de Azure <===
                            final Map<String, dynamic> datosSolicitud = {
                              "id_solicitante": _idUsuario,
                              "Motivo": motivoController.text,
                              "motivo": motivoController.text,
                              "hora_fecha_inicio_solicitada": horaFechaInicio,
                              "hora_fecha_conclusion_solicitada": horaFechaFin,
                              "garantia": garantiaSeleccionada,
                              "notas": equipoSeleccionado 
                            };

                            print("------------------------------------------------------------");
                            print("🚀 JSON ENVIADO AL BACKEND:");
                            print(jsonEncode(datosSolicitud));
                            print("------------------------------------------------------------");

                            try {
                              final url = Uri.parse('${ApiConfig.baseUrl}/api/solicitudes');
                              
                              final response = await http.post(
                                url,
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode(datosSolicitud),
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context); // Cierra loading dialog de forma segura

                              if (response.statusCode == 201 || response.statusCode == 200) {
                                Navigator.pop(context); // Cierra modal de forma segura
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('¡Solicitud creada correctamente!'), backgroundColor: Colors.green),
                                );
                                // Refresca de inmediato el calendario y el feed inferior
                                _obtenerSolicitudesBackend();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error del servidor (${response.statusCode}): ${response.body}'), backgroundColor: Colors.red),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context); // Cierra loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error de red: No se pudo conectar al servidor ($e)'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Guardar Reservación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24), 
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================================
  // TUTORIAL DE BIENVENIDA
  // =====================================================================
  void _mostrarTutorialNavegacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.menu_open, color: colorInstitucional, size: 50),
              const SizedBox(height: 12),
              Text(
                'Tu Panel de Usuario', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold, fontSize: 22)
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('El menú lateral contiene tus accesos directos de perfil y cierre de sesión seguro.', textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorInstitucional, foregroundColor: Colors.white),
              onPressed: () {
                _tutorialMostrado = true;
                Navigator.pop(context);
              },
              child: const Text('¡Entendido!'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: colorInstitucional,
        iconTheme: const IconThemeData(color: Colors.white),
        leadingWidth: 90, 
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/uaqlogo.png',
            height: 45, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.white, size: 30),
          ),
        ),
        title: const Text('Mi Agenda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(), 
          ),
          const SizedBox(width: 8), 
        ],
      ),
      endDrawer: Drawer(
        child: Stack(
          children: [
            Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: colorInstitucional),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_circle, color: Colors.white, size: 50),
                        SizedBox(width: 15),
                        Text('Menú Usuario', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home, color: colorInstitucional),
                  title: Text('Página principal', style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold)),
                  selected: true,
                  selectedTileColor: colorInstitucional.withOpacity(0.15),
                  onTap: () => Navigator.pop(context),   
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Mi Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const MiPerfilPage()));
                  }, 
                ),
              ],
            ),
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: FloatingActionButton.extended(
                heroTag: 'btnCerrarSesionUser',
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('id_usuario');

                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, TransicionElegante(page: const TipousuarioPage()));
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ), 
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _diaEnfocado,
              selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
              calendarFormat: _formatoCalendario,
              eventLoader: _obtenerEventosParaDia,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: colorInstitucional.withOpacity(0.5), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: colorInstitucional, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              onDaySelected: _alSeleccionarDia,
              onPageChanged: (focusedDay) => _diaEnfocado = focusedDay,
            ),
          ),
          const SizedBox(height: 20),
          
          // ===> LISTADO DINÁMICO COMPLETAMENTE ASOCIADO CON TU BASE DE DATOS <===
          Expanded(
            child: _cargandoSolicitudes 
              ? Center(child: CircularProgressIndicator(color: colorInstitucional))
              : ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _eventosDelDiaSeleccionado,
                  builder: (context, solicitudesLista, _) {
                    if (solicitudesLista.isEmpty) {
                      return Center(
                        child: Text('No hay actividades programadas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      );
                    }
                    return RefreshIndicator(
                      color: colorInstitucional,
                      onRefresh: _obtenerSolicitudesBackend,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: solicitudesLista.length,
                        itemBuilder: (context, index) {
                          final solicitud = solicitudesLista[index];
                          
                          // Mapeo estricto del JSON de tu Backend
                          final String motivo = solicitud['Motivo'] ?? 'Sin motivo especificado';
                          final int estatus = solicitud['estatus'] ?? 0;
                          final String horaIni = _extraerHoraDeString(solicitud['hora_fecha_inicio_solicitada']);
                          final String horaFin = _extraerHoraDeString(solicitud['hora_fecha_conclusion_solicitada']);
                          final String garantia = solicitud['garantia'] ?? 'Ninguna';

                          final colorEstado = _obtenerColorEstado(estatus);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorEstado.withOpacity(0.3), width: 1.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: colorEstado,
                                child: Icon(_obtenerIconoEstado(estatus), color: Colors.white, size: 20),
                              ),
                              title: Text(
                                '$horaIni - $horaFin | E: $garantia',
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorInstitucional, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Motivo: $motivo',
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorEstado,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _obtenerTextoEstado(estatus),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'btnAddReservacionUser',
        backgroundColor: colorInstitucional,
        foregroundColor: Colors.white,
        onPressed: _mostrarFormularioReservacion, 
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BotonHora extends StatelessWidget {
  final String titulo;
  final String valor;
  final VoidCallback onTap;

  const _BotonHora({required this.titulo, required this.valor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}