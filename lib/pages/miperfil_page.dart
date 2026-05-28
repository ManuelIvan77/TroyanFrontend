import 'dart:io'; // <--- Importación para manejar archivos
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <--- Importación de la galería

// =====================================================================
// IMPORTACIONES PARA NAVEGACIÓN
// =====================================================================
import 'package:inventarioss/utils/transicion_elegante.dart';
import 'package:inventarioss/pages/principal_user_page.dart'; 
import 'package:inventarioss/pages/tipousuario_page.dart';

class MiPerfilPage extends StatefulWidget {
  const MiPerfilPage({super.key});

  @override
  State<MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<MiPerfilPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color colorInstitucional = const Color(0xFF1A426E);

  // Variable para almacenar la imagen seleccionada
  File? _imagenPerfil;
  final ImagePicker _picker = ImagePicker();

  // =====================================================================
  // DATOS SIMULADOS DEL USUARIO ACTUAL
  // =====================================================================
  final Map<String, dynamic> _usuarioActual = {
    'nombre': 'Jean Emmanuel',
    'apellido': 'Aguilar Benítez',
    'ocupacion': 'Estudiante',
    'exp_clave': '284756',
    'correo': 'jaguilar@alumnos.uaq.mx',
    'status': true, 
  };

  // Función para obtener las iniciales
  String _obtenerIniciales(String nombre, String apellido) {
    String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String inicialApellido = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$inicialNombre$inicialApellido';
  }

  // =====================================================================
  // FUNCIÓN PARA SELECCIONAR IMAGEN DE LA GALERÍA
  // =====================================================================
  Future<void> _seleccionarImagen() async {
    try {
      final XFile? imagenSeleccionada = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 800, // Comprime ligeramente para mejor rendimiento
      );

      if (imagenSeleccionada != null) {
        setState(() {
          _imagenPerfil = File(imagenSeleccionada.path);
        });
        
        // Aquí podrías agregar la lógica para subir la imagen a tu base de datos/servidor
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar la imagen'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      
      // ==========================================
      // HEADER CLÁSICO
      // ==========================================
      appBar: AppBar(
        backgroundColor: colorInstitucional,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, 
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
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(), 
          ),
          const SizedBox(width: 8), 
        ],
      ),
      
      // ==========================================
      // DRAWER DE NAVEGACIÓN
      // ==========================================
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
                  leading: const Icon(Icons.home),
                  title: const Text('Página principal'),
                  onTap: () {
                     Navigator.pop(context);
                    Navigator.pushReplacement(context, TransicionElegante(page: const Principal_user_Page()));
                  }, 
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.person, color: colorInstitucional),
                  title: Text('Mi Perfil', style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold)),
                  selected: true,
                  selectedTileColor: colorInstitucional.withOpacity(0.15),
                  onTap: () => Navigator.pop(context), 
                ),
              ],
            ),
            
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: FloatingActionButton.extended(
                heroTag: 'btnCerrarSesionPerfil',
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 3,
                onPressed: () async {
                  Navigator.pop(context);
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
                  await Future.delayed(const Duration(seconds: 2));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const TipousuarioPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ), 
      
      // ==========================================
      // CUERPO DEL PERFIL
      // ==========================================
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorInstitucional,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                
                // ==========================================
                // AVATAR INTERACTIVO
                // ==========================================
                Positioned(
                  bottom: -50,
                  child: GestureDetector(
                    onTap: _seleccionarImagen, // Llama a la función al tocar
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF8F9FA), width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            // Muestra la imagen si existe, si no, es nulo
                            backgroundImage: _imagenPerfil != null ? FileImage(_imagenPerfil!) : null,
                            // Muestra las iniciales solo si NO hay imagen seleccionada
                            child: _imagenPerfil == null 
                                ? Text(
                                    _obtenerIniciales(_usuarioActual['nombre'], _usuarioActual['apellido']),
                                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorInstitucional),
                                  )
                                : null,
                          ),
                        ),
                        // Ícono indicador de cámara
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorInstitucional,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 60), 
            
            Text(
              '${_usuarioActual['nombre']} ${_usuarioActual['apellido']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _usuarioActual['ocupacion'] == 'Estudiante' ? Colors.blue.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _usuarioActual['ocupacion'].toUpperCase(),
                    style: TextStyle(
                      color: _usuarioActual['ocupacion'] == 'Estudiante' ? Colors.blue.shade900 : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _usuarioActual['status'] ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _usuarioActual['status'] ? Icons.check_circle : Icons.cancel, 
                        color: _usuarioActual['status'] ? Colors.green.shade700 : Colors.red.shade700, 
                        size: 16
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _usuarioActual['status'] ? 'ACTIVO' : 'BLOQUEADO',
                        style: TextStyle(
                          color: _usuarioActual['status'] ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    icono: Icons.badge,
                    titulo: 'Expediente / Clave',
                    valor: _usuarioActual['exp_clave'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icono: Icons.email,
                    titulo: 'Correo Institucional',
                    valor: _usuarioActual['correo'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icono: Icons.lock,
                    titulo: 'Contraseña',
                    valor: '••••••••'
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icono, required String titulo, required String valor, String? accionTexto, VoidCallback? onAccion}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorInstitucional.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colorInstitucional, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            if (accionTexto != null && onAccion != null)
              TextButton(
                onPressed: onAccion,
                child: Text(accionTexto, style: TextStyle(color: colorInstitucional, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}