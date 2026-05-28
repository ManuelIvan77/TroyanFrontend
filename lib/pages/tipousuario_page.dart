import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- NUEVO: Importación necesaria para bloquear la pantalla

import 'package:inventarioss/pages/inicio_Admin_page.dart';
import 'package:inventarioss/pages/inicio_user_page.dart';
import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/principal_user_page.dart';
//import 'package:inventarioss/pages/principal_page.dart';
//import 'package:inventarioss/pages/principal_user_page.dart';

// =====================================================================
// ¡IMPORTANTE! IMPORTACIÓN DE LA TRANSICIÓN
// =====================================================================
import 'package:inventarioss/utils/transicion_elegante.dart'; 

// Cambiamos a StatefulWidget para poder controlar cuándo se bloquea y desbloquea la pantalla
class TipousuarioPage extends StatefulWidget {
  const TipousuarioPage({Key? key}) : super(key: key);

  @override
  State<TipousuarioPage> createState() => _TipousuarioPageState();
}

class _TipousuarioPageState extends State<TipousuarioPage> {
  // Paleta de colores sobria
  final Color navyBlue = const Color(0xFF0A3161); // Azul Marino Clásico
  final Color elegantGray = const Color(0xFF6C757D); // Gris neutro
  final Color backgroundWhite = const Color(0xFFF8F9FA); // Blanco roto minimalista

  final double _alturaLogo = 120.0;

  @override
  void initState() {
    super.initState();
    // BLOQUEAR ROTACIÓN: Obligamos a que esta pantalla solo sea vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // LIBERAR ROTACIÓN: Al salir de esta pantalla, permitimos que el resto de la app sí pueda girar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        // Cambiamos el Center por un Padding principal
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            children: [
              // ==========================================
              // CONTENIDO PRINCIPAL CENTRADO
              // ==========================================
              // Expanded permite que esta columna tome todo el espacio posible,
              // empujando el texto inferior hasta abajo de manera natural.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícono representativo de la institución
                    Image.asset(
                      'assets/uaqlogo2.png', 
                      height: _alturaLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.account_balance, color: navyBlue, size: _alturaLogo);
                      },
                    ),
                    const SizedBox(height: 50),
                    
                    // Título principal
                    Text(
                      'Facultad de Informática',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtítulo
                    Text(
                      'Portal de Acceso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: elegantGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Botón Primario: Estudiantes
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          TransicionElegante(page: const Inicio_user_Page()), // cambiar el const por Inicio_user_Page()),
                        );
                      },
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
                        'Acceso Estudiantes y Docentes',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botón Secundario: Docentes / Personal (Estilo Outlined)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          TransicionElegante(page: const Inicio_Admin_Page()),  // cambiar el const por Inicio_Admin_Page()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navyBlue,
                        side: BorderSide(
                          color: elegantGray.withOpacity(0.5), 
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Acceso Administradores',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // FOOTER / TEXTO INFERIOR
              // ==========================================
              // Al estar fuera del Expanded, se quedará siempre anclado al fondo
              Text(
                'En caso de no ser parte de la institución ir a dirección',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: elegantGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}