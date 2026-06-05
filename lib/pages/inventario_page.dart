import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/lugares_pages.dart';
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; 
import 'package:inventarioss/api_config.dart'; 

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InventarioScreen();
  }
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

//class _OriginalScreenState extends State<InventarioScreen> {} // Mantenemos tu mixin intacto abajo

class _InventarioScreenState extends State<InventarioScreen> with TickerProviderStateMixin {
  TabController? _tabController; 
  String _opcionDesplegableSeleccionada = 'Configuración General';
  String _estatusAdmin = 'espera'; 

  List<Map<String, dynamic>> _datosLugares = [];
  List<Map<String, dynamic>> _datosInventario = [];
  bool _cargandoInventario = true;
  bool _cargandoLugares = true;

  @override
  void initState() {
    super.initState();
    _initCargaInicial();
  }

  Future<void> _initCargaInicial() async {
    await Future.wait([
      _obtenerLugaresDeServidor(),
      _obtenerInventarioDeServidor(),
    ]);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  Future<void> _obtenerLugaresDeServidor() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/lugares'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] == false) {
          final List<dynamic> datosRaw = jsonResponse['datos'] ?? [];
          if (!mounted) return;
          setState(() {
            _datosLugares = List<Map<String, dynamic>>.from(datosRaw);
            _cargandoLugares = false;
            if (_datosLugares.isNotEmpty) {
              _tabController?.dispose();
              _tabController = TabController(length: _datosLugares.length, vsync: this);
            }
          });
        }
      } else {
        if (mounted) setState(() => _cargandoLugares = false);
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoLugares = false);
      _mostrarMensajeError('Error al conectar con Azure para cargar lugares.');
    }
  }

  Future<void> _obtenerInventarioDeServidor({bool esSilencioso = false}) async {
    if (!esSilencioso) {
      setState(() => _cargandoInventario = true);
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/api/articulos'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] == false) {
          final List<dynamic> datosRaw = jsonResponse['datos'] ?? [];
          if (!mounted) return;
          setState(() {
            _datosInventario = datosRaw.map((item) {
              final int lugarBaseId = item['lugar_base'] ?? 0;
              final int? ubicacionId = item['ubicacion']; 
              String lugarDestinoActual = item['nombre_ubicacion_actual'] ?? item['nombre_lugar_base'] ?? 'Aún no hay valor atribuido';
              bool estaEnSuBase = (ubicacionId == null || ubicacionId == 0 || lugarBaseId == ubicacionId);

              return {
                'nSerie': (item['id_articulo'] ?? '').toString(), 
                'nombre': item['nombre'] ?? 'Aún no hay valor atribuido',
                'descripcion': item['descripcion'] ?? 'Aún no hay valor atribuido',
                'clave': item['clave'] ?? 'Aún no hay valor atribuido',
                'cantidad': 1, 
                'lugar': lugarDestinoActual,
                'lBase': estaEnSuBase, 
                'lugarBaseReal': item['nombre_lugar_base'] ?? 'Aún no hay valor atribuido'
              };
            }).toList();
            _cargandoInventario = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoInventario = false);
      _mostrarMensajeError('Error al conectar con Azure para cargar artículos.');
    }
  }

  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent)
    );
  }

  List<Map<String, dynamic>> _filtrarDatos(String lugar) {
    return _datosInventario.where((item) => item['lugar'].toString().toLowerCase() == lugar.toLowerCase()).toList();
  }

  String _generarNuevoNumeroSerie() {
    if (_datosInventario.isEmpty) return '001';
    int maxSerie = 0;
    for (var item in _datosInventario) {
      String numStr = item['nSerie'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (numStr.isNotEmpty) {
        int num = int.parse(numStr);
        if (num > maxSerie) maxSerie = num;
      }
    }
    return (maxSerie + 1).toString().padLeft(3, '0');
  }

  void _mostrarPantallaEspera() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange, size: 60),
              SizedBox(height: 16),
              Text('Cuenta en Revisión', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Tu estatus actual es "En espera". No puedes modificar el inventario hasta que el Administrador Principal apruebe tus permisos.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A426E), foregroundColor: Colors.white),
              onPressed: () {
                setState(() => _estatusAdmin = 'aprobado');
                Navigator.pop(context);
              },
              child: const Text('Simular Aprobación'),
            ),
          ],
        );
      }
    );
  }

  void _mostrarFormularioInventario() {
    if (_datosLugares.isEmpty) {
      _mostrarMensajeError('No se pueden agregar artículos porque no hay lugares cargados.');
      return;
    }
    String nuevoNumeroSerie = _generarNuevoNumeroSerie();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FormularioInventarioModal(
          datosLugares: _datosLugares,
          nuevoNumeroSerie: nuevoNumeroSerie,
          onGuardadoExitoso: () => _obtenerInventarioDeServidor(esSilencioso: true),
          onError: (msg) => _mostrarMensajeError(msg),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color(0xFF1A426E);

    if (_cargandoInventario || _cargandoLugares || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: colorInstitucional)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorInstitucional,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Inventarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer())),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: colorInstitucional),
              child: const Center(child: Icon(Icons.school, color: Colors.white, size: 40)),
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: colorInstitucional),
              title: const Text('Inventario', style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context), 
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: colorInstitucional,
            labelColor: Colors.black,
            isScrollable: true,
            tabs: _datosLugares.map((lugar) => Tab(text: lugar['nombre'] ?? 'Sin nombre')).toList(), 
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _datosLugares.map((lugar) => _buildTablaInventario(_filtrarDatos(lugar['nombre'] ?? ''))).toList(), 
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorInstitucional,
        foregroundColor: Colors.white,
        onPressed: () => _estatusAdmin == 'espera' ? _mostrarPantallaEspera() : _mostrarFormularioInventario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildTablaInventario(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Center(child: Text('No hay registros en esta ubicación.'));
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('N.Serie')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Descripcion')),
            DataColumn(label: Text('Clave')),
            DataColumn(label: Text('L.base')), // 👈 NUEVA COLUMNA AGREGADA
          ],
          rows: items.map((item) {
            final bool estaEnSuBase = item['lBase'] ?? false; // Lee tu booleano del GET

            return DataRow(cells: [
              DataCell(Text(item['nSerie'])),
              DataCell(Text(item['nombre'])),
              DataCell(Text(item['descripcion'])),
              DataCell(Text(item['clave'])),
              DataCell(
                Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: estaEnSuBase ? Colors.green : Colors.red, // 👈 Verde si coincide, rojo si no
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// =====================================================================
// 🛠️ COMPONENTE AUXILIAR FORMULARIO MODAL
// =====================================================================
class FormularioInventarioModal extends StatefulWidget {
  final List<Map<String, dynamic>> datosLugares;
  final String nuevoNumeroSerie;
  final VoidCallback onGuardadoExitoso;
  final Function(String) onError;

  const FormularioInventarioModal({
    super.key,
    required this.datosLugares,
    required this.nuevoNumeroSerie,
    required this.onGuardadoExitoso,
    required this.onError,
  });

  @override
  State<FormularioInventarioModal> createState() => _FormularioInventarioModalState();
}

class _FormularioInventarioModalState extends State<FormularioInventarioModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl, _descCtrl, _claveCtrl;
  bool _lBase = true;
  late Map<String, dynamic> _lugarActualSeleccionado, _lugarBaseSeleccionado;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _claveCtrl = TextEditingController();
    _lugarActualSeleccionado = widget.datosLugares.first;
    _lugarBaseSeleccionado = widget.datosLugares.length > 1 ? widget.datosLugares[1] : widget.datosLugares.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del equipo'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _claveCtrl,
                decoration: const InputDecoration(labelText: 'Clave'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _lugarActualSeleccionado,
                items: widget.datosLugares.map((l) => DropdownMenuItem(value: l, child: Text(l['nombre'] ?? ''))).toList(),
                onChanged: (val) => setState(() => _lugarActualSeleccionado = val!),
              ),
              SwitchListTile(
                title: const Text('¿Está en su lugar base?'),
                value: _lBase,
                onChanged: (val) => setState(() => _lBase = val),
              ),
              if (!_lBase)
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _lugarBaseSeleccionado,
                  items: widget.datosLugares.map((l) => DropdownMenuItem(value: l, child: Text(l['nombre'] ?? ''))).toList(),
                  onChanged: (val) => setState(() => _lugarBaseSeleccionado = val!),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    int idUbicacionActual = _lugarActualSeleccionado['id_lugar'];
                    int idLugarBase = _lBase ? idUbicacionActual : _lugarBaseSeleccionado['id_lugar'];

                    // MAPEO DIRECTO CON LAS VARIABLES DE TU BACKEND (DESESTRUCTURADAS)
                    final Map<String, dynamic> bodyPost = {
                      "nombre": _nombreCtrl.text.trim(),
                      "tipo": 0, // Por default en 0 (entero)
                      "clave": _claveCtrl.text.trim(),
                      "resguardante": 2, // ID numérico
                      "lugar_base": idLugarBase,         
                      "ubicacion": idUbicacionActual,    
                      "folio_resguardo": "FOL-2026-${widget.nuevoNumeroSerie}",
                      "descripcion": _descCtrl.text.trim(),
                      "imagen_url": null 
                    };

                    print("🚀 JSON ENVIADO AL BACKEND: ${jsonEncode(bodyPost)}");
                    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

                    try {
                      final url = Uri.parse('${ApiConfig.baseUrl}/api/articulos');
                      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(bodyPost));
                      if (context.mounted) Navigator.pop(context);

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        if (context.mounted) Navigator.pop(context);
                        widget.onGuardadoExitoso();
                      } else {
                        final datos =jsonDecode(response.body);
                        widget.onError('Error de servidor (${response.statusCode}) ${datos}');
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      final datos =jsonEncode(bodyPost);
                      widget.onError('No se pudo conectar con el servidor. ${datos}');
                    }
                  }
                },
                child: const Text('Guardar Artículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetFactorySerie extends StatelessWidget {
  final String nuevoNumeroSerie;
  const WidgetFactorySerie({super.key, required this.nuevoNumeroSerie});
  @override
  Widget build(BuildContext context) {
    return Text(nuevoNumeroSerie);
  }
}