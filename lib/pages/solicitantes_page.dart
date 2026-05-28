import 'package:flutter/material.dart';
import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/lugares_pages.dart'; // Corregido a lugares_page (sin la 's' extra)

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN
// =====================================================================
import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/inventario_page.dart';
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; // <--- IMPORTACIÓN PARA CERRAR SESIÓN

class SolicitantesPage extends StatelessWidget {
  const SolicitantesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: const SolicitantesScreen(),
    );
  }
}

class SolicitantesScreen extends StatefulWidget {
  const SolicitantesScreen({super.key});

  @override
  State<SolicitantesScreen> createState() => _SolicitantesScreenState();
}

class _SolicitantesScreenState extends State<SolicitantesScreen> {

  // Datos simulados para la tabla de solicitantes
  List<Map<String, dynamic>> _datosSolicitantes = [
    {
      'id': 'S-001',
      'nombre': 'Jean Emmanuel',
      'apellido': 'Aguilar Benítez',
      'ocupacion': 'Estudiante',
      'exp_clave': '284756',
      'correo': 'jaguilar@alumnos.uaq.mx',
      'contrasena': '••••••••',
      'status': true, // true = Activo (Verde)
    },
    {
      'id': 'S-002',
      'nombre': 'Emiliano',
      'apellido': 'García',
      'ocupacion': 'Estudiante',
      'exp_clave': '284757',
      'correo': 'egarcia@alumnos.uaq.mx',
      'contrasena': '••••••••',
      'status': true,
    },
    {
      'id': 'S-003',
      'nombre': 'Carlos',
      'apellido': 'Martínez',
      'ocupacion': 'Docente',
      'exp_clave': 'D-4482',
      'correo': 'cmartinez@docente.uaq.mx',
      'contrasena': '••••••••',
      'status': false, // false = Inactivo/Bloqueado (Rojo)
    },
    {
      'id': 'S-004',
      'nombre': 'Erick',
      'apellido': 'Gómez',
      'ocupacion': 'Docente',
      'exp_clave': 'D-8831',
      'correo': 'egomez@docente.uaq.mx',
      'contrasena': '••••••••',
      'status': true,
    },
    {
      'id': 'S-005',
      'nombre': 'Sofía',
      'apellido': 'Hernández',
      'ocupacion': 'Estudiante',
      'exp_clave': '291033',
      'correo': 'shernandez@alumnos.uaq.mx',
      'contrasena': '••••••••',
      'status': true,
    },
  ];

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
        
        title: const Text(
          'Solicitantes', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(), 
            ),
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
                        Image.asset(
                          'assets/uaqlogo.png',
                          height: 65, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.white, size: 40),
                        ),
                        const SizedBox(width: 15), 
                        Image.asset(
                          'assets/logoapp.png',
                          height: 75, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Página principal'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const PrincipalPage()), 
                    );
                  }, 
                ),
                
                ListTile(
                  leading: Icon(Icons.people, color: colorInstitucional),
                  title: Text(
                    'Solicitantes',
                    style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold),
                  ),
                  selected: true,
                  selectedTileColor: colorInstitucional.withOpacity(0.15),
                  onTap: () {
                    Navigator.pop(context);
                  }, 
                ),
                
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Administradores'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const AdminsPage()), 
                    );
                  }, 
                ),
                ListTile(
                  leading: const Icon(Icons.place),
                  title: const Text('Lugares'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const LugaresPage()),
                    );
                  }, 
                ),
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Inventario'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      TransicionElegante(page: const InventarioPage()),
                    );
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
            
            // Botón Flotante Gris en Drawer
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: FloatingActionButton(
                heroTag: null, 
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                elevation: 3,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abriendo configuraciones...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Icon(Icons.settings),
              ),
            ),
          ],
        ),
      ),
      
      // ==========================================
      // BODY: TABLA DE SOLICITANTES
      // ==========================================
      body: Container(
        color: const Color(0xFFE5E5E5), 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildTablaSolicitantes(_datosSolicitantes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaSolicitantes(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay registros de solicitantes.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD3D3D3),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ]
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFC0C0C0)),
            dataRowMinHeight: 45,
            dataRowMaxHeight: 50,
            horizontalMargin: 16,
            columnSpacing: 28,
            columns: const [
              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Apellido', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Ocupación', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Exp/Clave', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF666666),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        item['id'],
                        style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(Text(item['nombre'])),
                  DataCell(Text(item['apellido'])),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['ocupacion'] == 'Estudiante' ? Colors.blue.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['ocupacion'],
                        style: TextStyle(
                          color: item['ocupacion'] == 'Estudiante' ? Colors.blue.shade900 : Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(item['exp_clave'])),
                  DataCell(Text(item['correo'])),
                  DataCell(Text(item['contrasena'], style: const TextStyle(color: Colors.grey))),
                  
                  DataCell(
                    Center(
                      child: Tooltip(
                        message: item['status'] ? 'Bloquear usuario' : 'Activar usuario',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            setState(() {
                              item['status'] = !item['status'];
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  item['status'] 
                                    ? 'El usuario ${item['nombre']} ha sido Activado.' 
                                    : 'El usuario ${item['nombre']} ha sido Bloqueado.'
                                ),
                                backgroundColor: item['status'] ? Colors.green.shade700 : Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0), 
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item['status'] ? Colors.greenAccent[700] : Colors.redAccent[700],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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