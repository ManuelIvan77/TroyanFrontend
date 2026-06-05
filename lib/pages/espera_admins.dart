import 'dart:async'; // 👈 IMPORTANTE: Para usar el Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventarioss/api_config.dart';
// Importa tus páginas correspondientes
// import 'package:inventarioss/pages/principal_admin_page.dart'; 
// import 'package:inventarioss/utils/transicion_elegante.dart';

class AdminEsperaPage extends StatefulWidget {
  const AdminEsperaPage({Key? key}) : super(key: key);

  @override
  State<AdminEsperaPage> createState() => _AdminEsperaPageState();
}

class _AdminEsperaPageState extends State<AdminEsperaPage> {
  final Color navyBlue = const Color(0xFF0A3161);
  final Color elegantGray = const Color(0xFF6C757D);
  final Color backgroundWhite = const Color(0xFFF8F9FA);

  Timer? _timerConsulta; // ⏱️ El reloj que controlará el tiempo real
  bool _estaVerificando = false;

  @override
  void initState() {
    super.initState();
    // 🚀 En cuanto abre la pantalla, empieza a escuchar cada 5 segundos
    _iniciarEscuchaTiempoReal();
  }

  @override
  void dispose() {
    // 🛑 CRUCIAL: Apagar el reloj al salir de la pantalla para que no gaste batería ni internet
    _timerConsulta?.cancel();
    super.dispose();
  }

  // ===================================================================
  // 🔄 ESCUCHA EN TIEMPO REAL (POLLING)
  // ===================================================================
  void _iniciarEscuchaTiempoReal() {
    _timerConsulta = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _consultarEstatusBackend(silencioso: true);
    });
  }

  // ===================================================================
  // 🛰️ PETICIÓN AL BACKEND PARA REVISAR EL STATUS
  // ===================================================================
  Future<void> _consultarEstatusBackend({required bool silencioso}) async {
    if (!silencioso) {
      setState(() => _estaVerificando = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      // Obtenemos el ID del admin que guardamos previamente en el login/registro
      int? idAdmin = prefs.getInt('id_admin');

      if (idAdmin == null) return;

      // Suponiendo que tienes un endpoint para consultar un admin por ID
      final url = Uri.parse('${ApiConfig.baseUrl}/api/admins/$idAdmin');
      
      final response = await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extraemos el status (asumiendo que viene dentro de un nodo o directo en la raíz)
        int statusActual = responseData['status'] ?? responseData['admin']['status'] ?? 0;

        if (statusActual == 1) {
          // 🎉 ¡YA LO APROBARON! 
          _timerConsulta?.cancel(); // Detener el reloj inmediatamente

          // Guardamos en SharedPreferences que ya es status 1 para que no vuelva a entrar aquí
          await prefs.setInt('status_admin', 1);

          if (!mounted) return;

          // Lo mandamos directo y sin escalas a su Principal de Admin
          /*
          Navigator.pushReplacement(
            context,
            TransicionElegante(page: const Principal_Admin_Page()),
          );
          */
          
          print('🔥 ¡Aprobado en tiempo real! Redireccionando...');
        }
      }
    } catch (e) {
      print('❌ Error al checar el estatus en segundo plano: $e');
    }

    if (!silencioso) {
      setState(() => _estaVerificando = false);
    }
  }

  // ===================================================================
  // 🚪 CERRAR SESIÓN / ABANDONAR LA ESPERA
  // ===================================================================
  Future<void> _cerrarSesion() async {
    _timerConsulta?.cancel(); // Apagamos el reloj antes de salir
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id_admin'); 
    await prefs.remove('status_admin');

    if (!mounted) return;
    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    // El PopScope evita que tiren la pantalla hacia atrás con gestos
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: WillPopScope(
        onWillPop: () async => false, 
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Iconografía animada o fija de espera
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: navyBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(Icons.admin_panel_settings_rounded, size: 70, color: navyBlue),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'Acceso en Espera',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: navyBlue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu cuenta está registrada pero sigue **Inactiva (Status 0)**.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: elegantGray, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Estamos revisando tu estatus en tiempo real. En cuanto un Administrador te apruebe, entrarás automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navyBlue.withOpacity(0.8), height: 1.4),
                ),

                const Spacer(),

                // Botón manual por si el usuario está desesperado y quiere forzar la consulta
                ElevatedButton(
                  onPressed: _estaVerificando ? null : () => _consultarEstatusBackend(silencioso: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _estaVerificando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verificar ahora mismo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Volver al Login Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}