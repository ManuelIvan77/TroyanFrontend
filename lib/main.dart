import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- IMPORTACIÓN NECESARIA PARA BLOQUEAR ROTACIÓN

import 'package:inventarioss/pages/admins_page.dart';
import 'package:inventarioss/pages/inicio_Admin_page.dart';
import 'package:inventarioss/pages/inventario_page.dart';
import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:inventarioss/pages/tipousuario_page.dart';
import 'package:inventarioss/pages/inicio_user_page.dart';
import 'package:inventarioss/widgets/responsive_scaffold.dart';

void main() {
  // 1. OBLIGATORIO: Inicializa los componentes de Flutter antes de modificar el sistema
  WidgetsFlutterBinding.ensureInitialized();

  // 2. BLOQUEO GLOBAL: Fuerza a toda la aplicación a mantenerse en modo vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // 3. Ejecuta la aplicación solo cuando la orientación ya está fijada
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'caballo de troya',
      initialRoute: 'tipousuario_page', 
      routes: {
        'tipousuario_page': (BuildContext context) => const TipousuarioPage(),
        'inicio_Admin_page': (BuildContext context) => const Inicio_Admin_Page(),
        'inicio_user_page': (BuildContext context) => const Inicio_user_Page(),
        'inventario_page': (BuildContext context) => const InventarioPage(),
        'principal_page': (BuildContext context) => const PrincipalPage(),
        'solicitantes_page': (BuildContext context) => const SolicitantesPage(),
        'Admins_page': (BuildContext context) => const AdminsPage(),
      },
    );
  }
}