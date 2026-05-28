import 'package:flutter/material.dart';

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN
// =====================================================================
import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/lugares_pages.dart';
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; // <--- IMPORTACIÓN PARA CERRAR SESIÓN

void main() {
  runApp(const InventarioPage());
}

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario UAQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A426E),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const InventarioScreen(),
    );
  }
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _opcionDesplegableSeleccionada = 'Configuración General';

  // Simulación de permisos
  String _estatusAdmin = 'espera'; 

  // Datos de inventario
  List<Map<String, dynamic>> _datosInventario = [
    {'nSerie': '001', 'nombre': 'Cable Plug', 'descripcion': 'Cable', 'clave': '1231sfsa32', 'cantidad': 2, 'lBase': true, 'lugar': 'Caballo de Troya'},
    {'nSerie': '002', 'nombre': 'Cable Auxiliar', 'descripcion': 'Cable', 'clave': '324e543', 'cantidad': 4, 'lBase': true, 'lugar': 'Caballo de Troya'},
    {'nSerie': '003', 'nombre': 'Cable Auxiliar', 'descripcion': 'Cable', 'clave': '324ts3er', 'cantidad': 3, 'lBase': false, 'lugar': 'Caballo de Troya', 'lugarBaseReal': 'Oficina'},
    {'nSerie': '004', 'nombre': 'Batería', 'descripcion': 'Bombo y mas', 'clave': 'Tstetelt3242', 'cantidad': 1, 'lBase': true, 'lugar': 'Caballo de Troya'},
    {'nSerie': '011', 'nombre': 'Laptop Dell', 'descripcion': 'Equipo de cómputo', 'clave': 'LAP7723', 'cantidad': 5, 'lBase': true, 'lugar': 'Oficina'},
    {'nSerie': '012', 'nombre': 'Impresora HP', 'descripcion': 'Inyección de tinta', 'clave': 'IMP9901', 'cantidad': 1, 'lBase': false, 'lugar': 'Oficina', 'lugarBaseReal': 'Bodega'},
    {'nSerie': '013', 'nombre': 'Proyector Epson', 'descripcion': 'Multimedia', 'clave': 'PROY442', 'cantidad': 2, 'lBase': true, 'lugar': 'Bodega'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulación: Estatus cambiado a Aprobado')));
              },
              child: const Text('Simular Aprobación'),
            ),
          ],
        );
      }
    );
  }

  void _mostrarFormularioInventario() {
    final formKey = GlobalKey<FormState>();
    
    TextEditingController nombreCtrl = TextEditingController();
    TextEditingController descCtrl = TextEditingController();
    TextEditingController claveCtrl = TextEditingController();
    TextEditingController cantCtrl = TextEditingController(text: '1');
    
    bool lBase = true;
    String lugarSeleccionado = 'Caballo de Troya';
    String lugarBaseRealSeleccionado = 'Oficina'; 
    String nuevoNumeroSerie = _generarNuevoNumeroSerie();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85, 
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Agregar al Inventario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A426E))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  const Text('N. Serie', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(
                                    nuevoNumeroSerie,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: nombreCtrl,
                              decoration: InputDecoration(labelText: 'Nombre del equipo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: descCtrl,
                        decoration: InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: claveCtrl,
                              decoration: InputDecoration(labelText: 'Clave', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: cantCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: 'Cant.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: lugarSeleccionado,
                        decoration: InputDecoration(labelText: 'Lugar de destino actual', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: ['Caballo de Troya', 'Oficina', 'Bodega'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) => setModalState(() => lugarSeleccionado = val!),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('¿Está en su lugar base?', style: TextStyle(fontSize: 16)),
                                Switch(
                                  value: lBase,
                                  activeColor: Colors.green,
                                  onChanged: (val) => setModalState(() => lBase = val),
                                ),
                              ],
                            ),
                            
                            if (!lBase) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: lugarBaseRealSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Especifique su lugar base real', 
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: ['Caballo de Troya', 'Oficina', 'Bodega'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                onChanged: (val) => setModalState(() => lugarBaseRealSeleccionado = val!),
                              ),
                              const SizedBox(height: 8),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A426E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _datosInventario.add({
                                'nSerie': nuevoNumeroSerie, 
                                'nombre': nombreCtrl.text,
                                'descripcion': descCtrl.text,
                                'clave': claveCtrl.text,
                                'cantidad': int.tryParse(cantCtrl.text) ?? 1,
                                'lBase': lBase,
                                'lugar': lugarSeleccionado,
                                'lugarBaseReal': lBase ? lugarSeleccionado : lugarBaseRealSeleccionado, 
                              });
                            });
                            
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artículo agregado al inventario'), backgroundColor: Colors.green));
                          }
                        },
                        child: const Text('Guardar Artículo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _alPresionarAgregar() {
    if (_estatusAdmin == 'espera') {
      _mostrarPantallaEspera();
    } else {
      _mostrarFormularioInventario();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color colorInstitucional = const Color(0xFF1A426E);

    return Scaffold(
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
        title: const Text('Inventarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(icon: const Icon(Icons.menu, size: 28), onPressed: () => Scaffold.of(context).openEndDrawer()),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _opcionDesplegableSeleccionada,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), border: OutlineInputBorder()),
                    items: <String>['Configuración General', 'Cambiar Campus', 'Reportes Anuales'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (String? newValue) => setState(() => _opcionDesplegableSeleccionada = newValue!),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Página principal'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const PrincipalPage()));
                  }, 
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
                  leading: Icon(Icons.inventory, color: colorInstitucional),
                  title: Text('Inventario', style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold)),
                  selected: true,
                  selectedTileColor: colorInstitucional.withOpacity(0.15),
                  onTap: () => Navigator.pop(context), 
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
                              onPressed: () => Navigator.pop(context, false), 
                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text('Sí, salir'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmar != true) return;

                    if (!context.mounted) return;
                    Navigator.pop(context); // Cierra el menú lateral

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

                    await Future.delayed(const Duration(seconds: 3));

                    if (!context.mounted) return;

                    Navigator.pop(context); // Remueve el diálogo de carga

                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const TipousuarioPage()),
                    );
                  },
                ),
              ],
            ),
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorInstitucional,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: 'Caballo de Troya'),
                Tab(text: 'Oficina'),
                Tab(text: 'Bodega'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFE5E5E5),
              padding: const EdgeInsets.all(12.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTablaInventario(_filtrarDatos('Caballo de Troya')),
                  _buildTablaInventario(_filtrarDatos('Oficina')),
                  _buildTablaInventario(_filtrarDatos('Bodega')),
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorInstitucional,
        foregroundColor: Colors.white,
        onPressed: _alPresionarAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildTablaInventario(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay registros en esta ubicación.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD3D3D3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFC0C0C0)),
            dataRowMinHeight: 38,
            dataRowMaxHeight: 45,
            horizontalMargin: 12,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('N.Serie', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('L. Base', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(color: Color(0xFF666666)),
                      child: Text(
                        item['nSerie'],
                        style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                  DataCell(Text(item['nombre'])),
                  DataCell(Text(item['descripcion'])),
                  DataCell(Text(item['clave'])),
                  DataCell(Text(item['cantidad'].toString(), textAlign: TextAlign.center)),
                  
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item['lBase'] ? Colors.greenAccent[700] : Colors.redAccent[700],
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(0, 1))
                            ],
                          ),
                        ),
                        if (!item['lBase']) ...[
                          const SizedBox(width: 8),
                          Text(
                            item['lugarBaseReal'] ?? 'Desconocido', 
                            style: TextStyle(color: Colors.redAccent[700], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}