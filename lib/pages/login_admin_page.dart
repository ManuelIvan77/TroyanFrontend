import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:inventarioss/pages/principal_page.dart'; // Tu pantalla principal de Admin
import 'package:inventarioss/pages/inicio_admin_page.dart'; // Tu pantalla de registro de Admin
import 'package:inventarioss/pages/espera_admins.dart'; // Pantalla de escucha para status = 0
import 'package:inventarioss/utils/transicion_elegante.dart'; 
import 'package:inventarioss/api_config.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({Key? key}) : super(key: key);

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  final Color navyBlue = const Color(0xFF0A3161);
  final Color elegantGray = const Color(0xFF6C757D);
  final Color backgroundWhite = const Color(0xFFF8F9FA);

  final double _alturaLogo = 60.0;
  final double _espaciadoInferior = 15.0; 
  final double _espaciadoSuperior = 5.0; 
  bool _estaCargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA DE INICIO DE SESIÓN DE ADMINISTRADOR
  // ==========================================
  Future<void> _realizarLoginAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _estaCargando = true);
      
    final url = Uri.parse('${ApiConfig.baseUrl}/api/usuarios/login');

    final Map<String, dynamic> requestBody = {
      "correo": _correoController.text.trim(),
      "contrasena": _contrasenaController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      // 🟢 CASO 1: LOGIN EXITOSO (STATUS 200 - EL STATUS EN BD ES 1)
      if (response.statusCode == 200 && responseData['error'] == false) {
        int? idAsignado; 

        try {
          final Map<String, dynamic>? datosNode = responseData['datos'];
          
          if (datosNode != null) {
            idAsignado = datosNode['id_usuario'] ?? 
                         datosNode['id'] ?? 
                         datosNode['insertId'] ??
                         datosNode['id_generado'];
          }

          if (idAsignado != null) {
            final prefs = await SharedPreferences.getInstance();
            // Guardamos localmente las llaves bajo 'id_usuario' como requiere la persistencia
            await prefs.setInt('id_usuario', idAsignado);
            await prefs.setInt('status_admin', 1);
            
            if (datosNode?['nombre'] != null) {
              await prefs.setString('nombre_admin', datosNode!['nombre']);
            }
            if (datosNode?['tipo'] != null) {
              await prefs.setInt('tipo_admin', datosNode!['tipo']); 
            }
            
            print('------------------------------------------------------------');
            print('🛡️ LOGIN ADMIN ÉXITO: Sesión autorizada para id_usuario: $idAsignado');
            print('------------------------------------------------------------');
          } else {
            print('⚠️ Advertencia: No se encontró el ID en el nodo datos.');
          }
        } catch (e) {
          print('❌ Error procesando el JSON de Admin para el ID: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('¡Bienvenido Administrador! Iniciando...')),
              ],
            ),
            backgroundColor: navyBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 1), 
          ),
        );
        
        // Redirección elegante a la página principal
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return; 
          Navigator.pushReplacement(
            context,
            TransicionElegante(page: const PrincipalPage()),
          );
        });

      } 
      // 🟡 CASO 2: CUENTA RETENIDA / EN ESPERA (STATUS 403 - EL STATUS EN BD ES 0)
      else if (response.statusCode == 403) {
        int? idUsuarioPendiente;

        try {
          // Extraemos el ID ya sea de la raíz (403) o buscando en nodos alternos
          idUsuarioPendiente = responseData['id_usuario'] ?? 
                               (responseData['datos'] != null ? responseData['datos']['id_usuario'] : null);
          
          if (idUsuarioPendiente != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('id_usuario', idUsuarioPendiente);
            await prefs.setInt('status_admin', 0);
            
            print('------------------------------------------------------------');
            print('⏳ ADMIN PENDIENTE: id_usuario guardado para el Timer: $idUsuarioPendiente');
            print('------------------------------------------------------------');
          }
        } catch (e) {
          print('❌ Error extrayendo ID del JSON 403: $e');
        }

        if (!mounted) return;
        
        // Mostramos el mensaje descriptivo del backend
        _mostrarErrorSnackBar(responseData['mensaje'] ?? 'Cuenta en espera de aprobación.');

        // Redirección controlada tras mostrar el mensaje
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            TransicionElegante(page: const AdminEsperaPage()),
          );
        });
      } 
      // 🔴 CASO 3: CREDENCIALES ERRÓNEAS O FALLOS GENERALES
      else {
        _mostrarErrorSnackBar(responseData['mensaje'] ?? 'Credenciales incorrectas.');
      }
    } catch (e) {
      _mostrarErrorSnackBar('No se pudo conectar con el servidor.');
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }

  void _mostrarErrorSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Column(
        children: [
          // Header Estilo UAQ
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + _espaciadoSuperior,
              bottom: _espaciatedInferior(),
            ),
            decoration: BoxDecoration(
              color: navyBlue, 
              boxShadow: [
                BoxShadow(
                  color: navyBlue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/uaqlogo.png', 
                      height: _alturaLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.account_balance, color: Colors.white, size: _alturaLogo);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cuerpo del formulario perfectamente centrado
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Panel Administrativo',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales de administrador para continuar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: elegantGray,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Campo: Correo Institucional
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('Correo Institucional', Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingrese su correo.';
                          }
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@docente\.uaq\.mx$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Debe ser un correo institucional (@docente.uaq.mx)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Campo: Contraseña
                      TextFormField(
                        controller: _contrasenaController,
                        obscureText: true,
                        decoration: _buildInputDecoration('Contraseña', Icons.lock_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingrese su contraseña.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón de Envío Dinámico con Loader
                      ElevatedButton(
                        onPressed: _estaCargando ? null : _realizarLoginAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _estaCargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Ingresar como Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Vínculo Textual para redirección a registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Eres personal nuevo? ',
                            style: TextStyle(color: elegantGray, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                TransicionElegante(
                                  page: const Inicio_Admin_Page(),
                                ),
                              );
                            },
                            child: Text(
                              'Regístrate aquí',
                              style: TextStyle(
                                color: navyBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _espaciatedInferior() => _espaciadoInferior;

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      isDense: true, 
      labelText: labelText,
      labelStyle: TextStyle(color: elegantGray, fontSize: 13), 
      prefixIcon: Icon(icon, color: navyBlue, size: 20), 
      floatingLabelStyle: TextStyle(color: navyBlue),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), 
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: elegantGray.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: navyBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}