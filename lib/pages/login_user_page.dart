import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:inventarioss/pages/principal_user_page.dart';
import 'package:inventarioss/pages/inicio_user_page.dart'; 
import 'package:inventarioss/utils/transicion_elegante.dart'; 
import 'package:inventarioss/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  final Color navyBlue = const Color(0xFF0A3161);
  final Color elegantGray = const Color(0xFF6C757D);
  final Color backgroundWhite = const Color(0xFFF8F9FA);

  final double _alturaLogo = 60.0;
  final double _espaciadoInferior = 15.0; 
  final double _espaciadoSuperior = 5.0; 

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA DE INICIO DE SESIÓN (LOGIN)
  // ==========================================
  Future<void> _realizarLogin() async {
    if (_formKey.currentState!.validate()) {
      
      final url = Uri.parse('${ApiConfig.baseUrl}/api/solicitantes/login');

      final Map<String, dynamic> requestBody = {
        "correo": _correoController.text.trim(),
        "contraseña": _contrasenaController.text.trim(),
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['error'] == false) {
          
          int? idAsignado; 

          // ===================================================================
          // 🔑 CAPTURA EXACTA DE ID IGUAL QUE EN INICIO_USER_PAGE
          // ===================================================================
          try {
            // Tu backend del Login anida el mapa del usuario en la propiedad 'usuario'
            final Map<String, dynamic>? usuarioNode = responseData['usuario'];
            
            if (usuarioNode != null) {
              // Aplicamos exactamente la misma lógica de cascada (??) de tu archivo original
              idAsignado = usuarioNode['id_generado'] ?? 
                           usuarioNode['id_solicitante'] ?? 
                           usuarioNode['insertId'] ?? 
                           usuarioNode['id'];
            }

            if (idAsignado != null) {
              final prefs = await SharedPreferences.getInstance();
              // Guardado bajo la misma llave idéntica 'id_usuario' que lee Principal_user_Page
              await prefs.setInt('id_usuario', idAsignado);
              
              print('------------------------------------------------------------');
              print('🛡️ LOGIN ÉXITO: Sesión guardada localmente para id_usuario: $idAsignado');
              print('------------------------------------------------------------');
            } else {
              print('⚠️ Advertencia: No se encontró una propiedad de ID válida en el nodo usuario.');
            }
          } catch (e) {
            print('❌ Error procesando el JSON de respuesta para el ID: $e');
          }
          // ===================================================================

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('¡Bienvenido! Iniciando sesión...'),
                  ),
                ],
              ),
              backgroundColor: navyBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 1), 
            ),
          );
          
          // 🚀 NAVEGACIÓN A LA PÁGINA PRINCIPAL
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return; 
            
            Navigator.pushReplacement(
              context,
              TransicionElegante(
                page: const Principal_user_Page(), 
              ),
            );
          });

        } else {
          _mostrarErrorSnackBar(responseData['mensaje'] ?? 'Credenciales incorrectas.');
        }
      } catch (e) {
        _mostrarErrorSnackBar('No se pudo conectar con el servidor.');
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
        duration: const Duration(seconds: 2),
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
              bottom: _espaciadoInferior,
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

          // Cuerpo del formulario
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
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales institucionales para continuar.',
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
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@(alumnos\.uaq\.mx|docente\.uaq\.mx)$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Debe ser un correo de @alumnos o @docente .uaq.mx';
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

                      // Botón de Envío
                      ElevatedButton(
                        onPressed: _realizarLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Vínculo Textual para redirección a tu página de registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta? ',
                            style: TextStyle(color: elegantGray, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                TransicionElegante(
                                  page: const Inicio_user_Page(),
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