import 'package:flutter/material.dart';

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN Y CIERRE DE SESIÓN
// =====================================================================
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/tipousuario_page.dart'; // <--- IMPORTACIÓN PARA REGRESAR AL LOGIN
import 'package:inventarioss/widgets/responsive_scaffold.dart';

class AdminsPage extends StatefulWidget {
  const AdminsPage({super.key});

  @override
  State<AdminsPage> createState() => _AdministradoresPageState();
}

class _AdministradoresPageState extends State<AdminsPage> {
  // Datos simulados completos para la tabla de administradores
  List<Map<String, dynamic>> _datosAdministradores = [
    {
      'id': 'ADM-01',
      'nombre': 'Maria Remedios',
      'apellido': 'Guzman',
      'tipo': 'Super Admin',
      'exp_clave': 'AD-8841',
      'correo': 'jaguilar.admin@uaq.mx',
      'contrasena': '••••••••',
      'status': true, // El Super Admin suele estar aprobado por defecto (Verde)
    },
    {
      'id': 'ADM-02',
      'nombre': 'Roberto',
      'apellido': 'Sánchez',
      'tipo': 'Gestor',
      'exp_clave': 'AD-2234',
      'correo': 'rsanchez.admin@uaq.mx',
      'contrasena': '••••••••',
      'status': false, // En espera (Rojo)
    },
    {
      'id': 'ADM-03',
      'nombre': 'Mariana',
      'apellido': 'López',
      'tipo': 'Auditor',
      'exp_clave': 'AD-5519',
      'correo': 'mlopez.admin@uaq.mx',
      'contrasena': '••••••••',
      'status': false, // En espera (Rojo)
    },
    {
      'id': 'ADM-04',
      'nombre': 'Emiliano',
      'apellido': 'García',
      'tipo': 'Gestor',
      'exp_clave': 'AD-2290',
      'correo': 'egarcia.admin@uaq.mx',
      'contrasena': '••••••••',
      'status': false, // En espera (Rojo)
    },
  ];

  // =====================================================================
  // FUNCIÓN DE CIERRE DE SESIÓN (Confirmación + Carga + Redirección)
  // =====================================================================
  Future<void> _ejecutarCerrarSesion(BuildContext context) async {
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

    // 3. Cierra el menú lateral (Drawer) si fue llamado desde ahí
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
  }

  @override
  Widget build(BuildContext context) {
    // LLAMAMOS AL WIDGET MAESTRO
    return ResponsiveScaffold(
      titulo: 'Administradores',
      paginaActual: 'Administradores', 
      
      cuerpo: Container(
        color: const Color(0xFFE5E5E5), 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildTablaResponsiva(_datosAdministradores, constraints);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generador dinámico de la tabla con adaptabilidad responsiva
  Widget _buildTablaResponsiva(List<Map<String, dynamic>> items, BoxConstraints constraints) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay registros de administradores.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
              
              columnSpacing: constraints.maxWidth > 800 ? 40 : 20, 
              horizontalMargin: 16,
              
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Apellido', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Exp/Clave', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              ],
              rows: items.map((item) {
                
                Color bgColor;
                Color textColor;
                
                switch(item['tipo']) {
                  case 'Super Admin':
                    bgColor = Colors.deepPurple.shade100;
                    textColor = Colors.deepPurple.shade900;
                    break;
                  case 'Gestor':
                    bgColor = Colors.teal.shade100;
                    textColor = Colors.teal.shade900;
                    break;
                  case 'Auditor':
                  default:
                    bgColor = Colors.blueGrey.shade100;
                    textColor = Colors.blueGrey.shade900;
                    break;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
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
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['tipo'],
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(Text(item['exp_clave'])),
                    DataCell(Text(item['correo'])),
                    DataCell(
                      Text(item['contrasena'], style: const TextStyle(color: Colors.grey, letterSpacing: 2))
                    ),
                    
                    // ========================================================
                    // COLUMNA STATUS (CON BLOQUEO PARA SUPER ADMIN)
                    // ========================================================
                    DataCell(
                      Center(
                        child: item['tipo'] == 'Super Admin' 
                          ? Tooltip(
                              message: 'Permisos fijos de Super Admin',
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.greenAccent[700], // Siempre en verde
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
                            )
                          : Tooltip(
                              message: item['status'] ? 'Revocar aprobación' : 'Aprobar administrador',
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
                                          ? 'El administrador ${item['nombre']} ha sido APROBADO.' 
                                          : 'Se ha REVOCADO el acceso a ${item['nombre']}.'
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
      ),
    );
  }
}