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
// Asegúrate de que esta importación apunte a donde Jean guardó el archivo de configuración base de la API
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

  late Map<DateTime, List<String>> _eventos;
  late final ValueNotifier<List<String>> _eventosDelDiaSeleccionado;

  final Color colorInstitucional = const Color(0xFF1A426E);

  // ===> VARIABLE GLOBAL PARA EL ID DEL SOLICITANTE <===
  int _idUsuario = 0;

  // Inventario local para diseño de interfaz
  final List<String> _inventarioNombres = [
    'Laptop Dell XPS',
    'MacBook Air M2',
    'Proyector Epson U50',
    'Cámara Canon T7i',
    'Trípode Manfrotto',
    'Micrófono Shure SM58',
    'Kit Iluminación LED',
    'Cable HDMI 10m',
    'Bocina Bluetooth JBL',
  ];

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Carga síncrona del ID guardado por el Login o Registro
    _cargarDatosUsuario();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tutorialMostrado) {
        _mostrarTutorialNavegacion();
      }
    });

    _diaSeleccionado = _diaEnfocado;
    
    final hoy = DateTime.now();
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    final manana = hoyNormalizado.add(const Duration(days: 1));
    final proximaSemana = hoyNormalizado.add(const Duration(days: 7));

    _eventos = {
      hoyNormalizado: [
        '10:00 - 12:00 | Revisión de inventario en Bodega',
      ],
      manana: [
        '09:00 - 11:00 | Préstamo de proyector',
      ],
      proximaSemana: [
        '16:00 - 18:00 | Práctica en Caballo de Troya',
      ],
    };

    _eventosDelDiaSeleccionado = ValueNotifier(_obtenerEventosParaDia(_diaSeleccionado!));
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

  @override
  void dispose() {
    _eventosDelDiaSeleccionado.dispose();
    super.dispose();
  }

  List<String> _obtenerEventosParaDia(DateTime dia) {
    final diaNormalizado = DateTime(dia.year, dia.month, dia.day);
    return _eventos[diaNormalizado] ?? [];
  }

  void _alSeleccionarDia(DateTime diaSeleccionado, DateTime diaEnfocado) {
    if (!isSameDay(_diaSeleccionado, diaSeleccionado)) {
      setState(() {
        _diaSeleccionado = diaSeleccionado;
        _diaEnfocado = diaEnfocado;
      });
      _eventosDelDiaSeleccionado.value = _obtenerEventosParaDia(diaSeleccionado);
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
                          labelText: 'Equipo Solicitado (Solo Vista)',
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

                      // ================================================================
                      // ACCIÓN PRINCIPAL DE DISPARO HTTP POST
                      // ================================================================
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
                            
                            // Conversión a estampa YYYY-MM-DD HH:MM:SS
                            final String fechaBase = "${_diaSeleccionado!.year}-${_diaSeleccionado!.month.toString().padLeft(2, '0')}-${_diaSeleccionado!.day.toString().padLeft(2, '0')}";
                            final String horaFechaInicio = "$fechaBase $horaInicioStr:00";
                            final String horaFechaFin = "$fechaBase $horaEntregaStr:00";

                            // ===> GENERACIÓN EXCLUSIVA DE DATOS PARA TU REQ.BODY <===
                            final Map<String, dynamic> datosSolicitud = {
                              "id_solicitante": _idUsuario,
                              "motivo": motivoController.text,
                              "hora_fecha_inicio_solicitada": horaFechaInicio,
                              "hora_fecha_conclusion_solicitada": horaFechaFin,
                              "garantia": garantiaSeleccionada,
                              "notes": null 
                            };

                            // INSPECTOR VISUAL REQUERIDO EN CONSOLA
                            print("------------------------------------------------------------");
                            print("🚀 JSON ENVIADO AL BACKEND:");
                            print(jsonEncode(datosSolicitud));
                            print("------------------------------------------------------------");

                            try {
                              // ================================================================
                              // NUEVA RUTA INTEGRADA CON APICONFIG (REEMPLAZA LOCALHOST)
                              // ================================================================
                              final url = Uri.parse('${ApiConfig.baseUrl}/api/solicitudes');
                              
                              final response = await http.post(
                                url,
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode(datosSolicitud),
                              );

                              if (context.mounted) Navigator.pop(context); // Cierra loading

                              if (response.statusCode == 201 || response.statusCode == 200) {
                                String nuevoEvento = '$horaInicioStr - $horaEntregaStr | $equipoSeleccionado ($garantiaSeleccionada)';
                                final diaNormalizado = DateTime(_diaSeleccionado!.year, _diaSeleccionado!.month, _diaSeleccionado!.day);
                                
                                setState(() {
                                  if (_eventos[diaNormalizado] != null) {
                                    _eventos[diaNormalizado]!.add(nuevoEvento);
                                  } else {
                                    _eventos[diaNormalizado] = [nuevoEvento];
                                  }
                                  _eventosDelDiaSeleccionado.value = List.from(_eventos[diaNormalizado]!);
                                });
                                
                                if (context.mounted) {
                                  Navigator.pop(context); // Cierra modal inferior
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('¡Solicitud creada correctamente!'), backgroundColor: Colors.green),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error del servidor (${response.statusCode}): ${response.body}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error de red: No se pudo conectar al servidor ($e)'), backgroundColor: Colors.red),
                                );
                              }
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('El menú lateral contiene tus accesos directos de perfil y cierre de sesión seguro.', textAlign: TextAlign.center),
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
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle, color: Colors.white, size: 50),
                        const SizedBox(width: 15),
                        const Text('Menú Usuario', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            child: TableCalendar<String>(
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
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _eventosDelDiaSeleccionado,
              builder: (context, eventosLista, _) {
                if (eventosLista.isEmpty) {
                  return Center(
                    child: Text('No hay actividades programadas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: eventosLista.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: Icon(Icons.task_alt, color: colorInstitucional),
                        title: Text(eventosLista[index], style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
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