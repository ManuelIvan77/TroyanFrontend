import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventarioss/utils/transicion_elegante.dart'; 
import 'package:inventarioss/pages/principal_page.dart';

class Inicio_Admin_Page extends StatefulWidget {
  const Inicio_Admin_Page({Key? key}) : super(key: key);

  @override
  State<Inicio_Admin_Page> createState() => _InicioAdminPageState();
}

class _InicioAdminPageState extends State<Inicio_Admin_Page> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();
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
    _nombreController.dispose();
    _apellidoController.dispose();
    _claveController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Validación exitosa. Iniciando sesión...'),
            ],
          ),
          backgroundColor: navyBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 1), 
        ),
      );
      
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          TransicionElegante(page: const PrincipalPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Column(
        children: [
          // ==========================================
          // HEADER DINÁMICO
          // ==========================================
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

          // ==========================================
          // CUERPO DEL FORMULARIO
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registro de Personal',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingrese sus datos institucionales para continuar.',
                      style: TextStyle(
                        fontSize: 14,
                        color: elegantGray,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration('Nombre(s)', Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingrese su nombre.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration('Apellido(s)', Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingrese su apellido.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Campo: Exp/Clave (Ahora abarca todo el ancho)
                    TextFormField(
                      controller: _claveController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _buildInputDecoration('Exp/Clave', Icons.key_outlined).copyWith(counterText: ''),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese su clave.';
                        }
                        if (value.trim().length != 6) {
                          return 'Deben ser 6 dígitos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

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
                        if (value.trim().length < 8) {
                          return 'Debe tener al menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),

                    // Botón de Envío
                    ElevatedButton(
                      onPressed: _handleLogin,
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
                        'Verificar e Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FUNCIÓN PARA EL ESTILO DE LOS CAMPOS
  // ==========================================
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