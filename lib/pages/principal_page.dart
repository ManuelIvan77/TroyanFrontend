import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/lugares_pages.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:table_calendar/table_calendar.dart';

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN
// =====================================================================
import 'package:inventarioss/pages/inventario_page.dart';
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; // <--- IMPORTACIÓN PARA REGRESAR AL LOGIN

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  // Llave global para controlar el Scaffold y abrir el menú programáticamente
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Variable estática: Asegura que el tutorial solo se muestre 1 vez por sesión
  static bool _tutorialMostrado = false;

  // Variables de estado para el calendario
  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado;

  late Map<DateTime, List<String>> _eventos;
  late final ValueNotifier<List<String>> _eventosDelDiaSeleccionado;

  final Color colorInstitucional = const Color(0xFF1A426E);

  @override
  void initState() {
    super.initState();
    
    // Bloqueo de rotación
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Lanzador del tutorial visual
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
        '14:00 - 16:00 | Junta de revisión de UI'
      ],
      manana: [
        '09:00 - 11:00 | Sincronización del proyecto con Emiliano',
        '11:30 - 13:00 | Pruebas de flujo de datos para Smartrace'
      ],
      proximaSemana: [
        '16:00 - 18:00 | Presentación de mockups para Gourmet Bolis',
      ],
    };

    _eventosDelDiaSeleccionado = ValueNotifier(_obtenerEventosParaDia(_diaSeleccionado!));
  }

  @override
  void dispose() {
    _eventosDelDiaSeleccionado.dispose();
    super.dispose();
  }

  // =====================================================================
  // TUTORIAL DE NAVEGACIÓN (MEJORADO VISUALMENTE)
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
                'Tu Panel de Control', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold, fontSize: 22)
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El menú lateral (arriba a la derecha) es tu herramienta principal para gestionar el sistema. Desde ahí podrás acceder a:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                _buildTutorialItem(Icons.calendar_month, 'Agenda Principal', 'Añade y visualiza reservaciones de equipo.'),
                _buildTutorialItem(Icons.people, 'Usuarios', 'Controla los accesos de solicitantes y administradores.'),
                _buildTutorialItem(Icons.place, 'Lugares', 'Administra las ubicaciones físicas (Oficina, Bodega...).'),
                _buildTutorialItem(Icons.inventory, 'Inventario', 'Revisa existencias, añade y gestiona materiales.'),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorInstitucional,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              onPressed: () {
                _tutorialMostrado = true;
                Navigator.pop(context);
                
                Future.delayed(const Duration(milliseconds: 300), () {
                  _scaffoldKey.currentState?.openEndDrawer();
                });
              },
              child: const Text('¡Entendido, vamos a verlo!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildTutorialItem(IconData icon, String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorInstitucional.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorInstitucional, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(descripcion, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // LÓGICA DE EVENTOS Y RESERVACIONES
  // =====================================================================
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

  void _mostrarFormularioReservacion() {
    final formKey = GlobalKey<FormState>();
    
    TextEditingController equipoController = TextEditingController();
    TextEditingController motivoController = TextEditingController();
    
    TimeOfDay? horaInicio;
    TimeOfDay? horaEntrega;
    String? garantiaSeleccionada;
    final DateTime horaRegistro = DateTime.now(); 

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
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Registrado el: ${horaRegistro.day}/${horaRegistro.month}/${horaRegistro.year} a las ${horaRegistro.hour.toString().padLeft(2, '0')}:${horaRegistro.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),

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
                           padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                           child: Text('Ambas horas son obligatorias*', style: TextStyle(color: Colors.red, fontSize: 12)),
                         ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: equipoController,
                        decoration: InputDecoration(
                          labelText: 'Equipo Solicitado',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.devices),
                        ),
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
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
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorInstitucional,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate() && horaInicio != null && horaEntrega != null) {
                            String nuevoEvento = '${formatearHora(horaInicio)} - ${formatearHora(horaEntrega)} | ${equipoController.text} (${garantiaSeleccionada})';
                            final diaNormalizado = DateTime(_diaSeleccionado!.year, _diaSeleccionado!.month, _diaSeleccionado!.day);
                            
                            setState(() {
                              if (_eventos[diaNormalizado] != null) {
                                _eventos[diaNormalizado]!.add(nuevoEvento);
                              } else {
                                _eventos[diaNormalizado] = [nuevoEvento];
                              }
                            });
                            
                            _eventosDelDiaSeleccionado.value = List.from(_eventos[diaNormalizado]!);
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reservación añadida con éxito'), backgroundColor: Colors.green),
                            );
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
        title: const Text('Agenda Principal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/uaqlogo.png', height: 65, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.white, size: 40)),
                        const SizedBox(width: 15), 
                        Image.asset('assets/logoapp.png', height: 75, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps, color: Colors.white, size: 40)),
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
                  leading: const Icon(Icons.people),
                  title: const Text('Solicitantes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const SolicitantesPage()));
                  }, 
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Administradores'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const AdminsPage()));
                  }, 
                ),
                ListTile(
                  leading: const Icon(Icons.place),
                  title: const Text('Lugares'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const LugaresPage()));
                  }, 
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Inventario'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const InventarioPage()));
                  },
                ),
                const Divider(),
                
                // =========================================================
                // LISTTILE DE CERRAR SESIÓN (CON CONFIRMACIÓN Y RETRASO)
                // =========================================================
                ListTile(
                  leading: Icon(Icons.exit_to_app_rounded, color: Colors.red.shade700),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    // 1. Mostrar diálogo de confirmación antes de hacer cualquier cosa
                    bool? confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          title: const Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Cerrar Sesión'),
                            ],
                          ),
                          content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false), // Retorna false
                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(context, true), // Retorna true
                              child: const Text('Sí, salir'),
                            ),
                          ],
                        );
                      },
                    );

                    // 2. Si el usuario selecciona "Cancelar" o toca fuera de la caja, detenemos el proceso
                    if (confirmar != true) return;

                    // 3. Cierra el menú lateral (Drawer)
                    if (!context.mounted) return;
                    Navigator.pop(context);

                    // 4. Lanza la ventana emergente de procesamiento
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return const AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF1A426E)),
                                SizedBox(width: 20),
                                Text('Cerrando sesión...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }
                    );

                    // 5. Simula la espera de 3 segundos
                    await Future.delayed(const Duration(seconds: 3));

                    // 6. Valida si la pantalla sigue activa
                    if (!context.mounted) return;

                    // Remueve el diálogo de carga
                    Navigator.pop(context);

                    // 7. Destruye la pila actual y manda a la vista de login inicial
                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const TipousuarioPage()),
                    );
                  },
                ),
              ],
            ),
            
            // El botón original de configuraciones se mantiene intacto abajo
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: FloatingActionButton(
                heroTag: null,
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                elevation: 3,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo configuraciones...'), behavior: SnackBarBehavior.floating));
                },
                child: const Icon(Icons.settings),
              ),
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
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
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
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No hay actividades programadas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: eventosLista.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: colorInstitucional.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.task_alt, color: colorInstitucional),
                        ),
                        title: Text(eventosLista[index], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        trailing: IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
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