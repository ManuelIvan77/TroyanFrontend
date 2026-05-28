import 'package:flutter/material.dart';

// =====================================================================
// IMPORTACIONES DE TODAS TUS PÁGINAS
// =====================================================================
import 'package:inventarioss/pages/lugares_pages.dart';
import 'package:inventarioss/pages/principal_page.dart';
import 'package:inventarioss/pages/inventario_page.dart';
import 'package:inventarioss/pages/solicitantes_page.dart';
import 'package:inventarioss/pages/admins_page.dart'; 
import 'package:inventarioss/pages/miperfil_page.dart'; // <--- IMPORTACIÓN DE MI PERFIL
import 'package:inventarioss/pages/tipousuario_page.dart'; 
import 'package:inventarioss/utils/transicion_elegante.dart';

class ResponsiveScaffold extends StatefulWidget {
  final Widget cuerpo;
  final String paginaActual; 
  final String titulo;

  const ResponsiveScaffold({
    Key? key,
    required this.titulo,
    required this.cuerpo,
    required this.paginaActual,
  }) : super(key: key);

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  // Llave maestra para controlar el Scaffold y el Drawer de forma segura
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final Color colorInstitucional = const Color(0xFF1A426E);

  // =================================================================
  // LÓGICA DE CIERRE DE SESIÓN GLOBAL (Segura para Móvil y PC)
  // =================================================================
  Future<void> _ejecutarCerrarSesion(BuildContext context) async {
    // 1. Mostrar diálogo de confirmación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
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

    // 2. Cerramos el Drawer SOLAMENTE si está abierto (evita errores en PC)
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }

    // 3. Mostramos la ventana de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
      },
    );

    // 4. Retraso de 3 segundos
    await Future.delayed(const Duration(seconds: 3));

    if (!context.mounted) return;

    // 5. Quitamos la carga usando el rootNavigator para mayor seguridad
    Navigator.of(context, rootNavigator: true).pop();

    // 6. Limpiamos TODA la pila de navegación y regresamos al Login
    Navigator.pushAndRemoveUntil(
      context,
      TransicionElegante(page: const TipousuarioPage()),
      (Route<dynamic> route) => false, // Borra el historial previo
    );
  }

  // =================================================================
  // LÓGICA DE NAVEGACIÓN INTELIGENTE
  // =================================================================
  void _navegarA(BuildContext context, String destino, Widget pagina) {
    // Si ya estamos en la página, solo cerramos el menú
    if (widget.paginaActual == destino) {
      if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
        _scaffoldKey.currentState?.closeEndDrawer();
      }
      return;
    }
    
    // Si vamos a otra página, cerramos el menú (si está abierto) y navegamos
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
    
    Navigator.pushReplacement(
      context,
      TransicionElegante(page: pagina),
    );
  }

  // =================================================================
  // EL MENÚ LATERAL REUTILIZABLE (DRAWER / PANEL)
  // =================================================================
  Widget _construirMenuLateral(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorInstitucional),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/uaqlogo.png', 
                        height: 65, 
                        errorBuilder: (c, e, s) => const Icon(Icons.school, color: Colors.white, size: 40)
                      ),
                      const SizedBox(width: 15),
                      Image.asset(
                        'assets/logoapp.png', 
                        height: 65, 
                        errorBuilder: (c, e, s) => const Icon(Icons.apps, color: Colors.white, size: 40)
                      ),
                    ],
                  ),
                ),
              ),
              
              // 1. Página Principal
              ListTile(
                leading: Icon(Icons.home, color: widget.paginaActual == 'Principal' ? colorInstitucional : Colors.grey),
                title: Text(
                  'Página principal', 
                  style: TextStyle(
                    color: widget.paginaActual == 'Principal' ? colorInstitucional : Colors.black, 
                    fontWeight: widget.paginaActual == 'Principal' ? FontWeight.bold : FontWeight.normal
                  )
                ),
                selected: widget.paginaActual == 'Principal',
                selectedTileColor: colorInstitucional.withOpacity(0.15),
                onTap: () => _navegarA(context, 'Principal', const PrincipalPage()),
              ),
              
              const Divider(),

              // 2. Mi Perfil
              ListTile(
                leading: const Icon(Icons.person, color: Colors.grey),
                title: const Text('Mi Perfil', style: TextStyle(color: Colors.black)),
                onTap: () {
                  if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
                    _scaffoldKey.currentState?.closeEndDrawer();
                  }
                  Navigator.push(
                    context,
                    TransicionElegante(page: const MiPerfilPage()),
                  );
                },
              ),

              const Divider(),
              
              // 3. Solicitantes
              ListTile(
                leading: Icon(Icons.people, color: widget.paginaActual == 'Solicitantes' ? colorInstitucional : Colors.grey),
                title: Text(
                  'Solicitantes', 
                  style: TextStyle(
                    color: widget.paginaActual == 'Solicitantes' ? colorInstitucional : Colors.black, 
                    fontWeight: widget.paginaActual == 'Solicitantes' ? FontWeight.bold : FontWeight.normal
                  )
                ),
                selected: widget.paginaActual == 'Solicitantes',
                selectedTileColor: colorInstitucional.withOpacity(0.15),
                onTap: () => _navegarA(context, 'Solicitantes', const SolicitantesPage()),
              ),
              
              // 4. Administradores
              ListTile(
                leading: Icon(Icons.people, color: widget.paginaActual == 'Administradores' ? colorInstitucional : Colors.grey),
                title: Text(
                  'Administradores', 
                  style: TextStyle(
                    color: widget.paginaActual == 'Administradores' ? colorInstitucional : Colors.black, 
                    fontWeight: widget.paginaActual == 'Administradores' ? FontWeight.bold : FontWeight.normal
                  )
                ),
                selected: widget.paginaActual == 'Administradores',
                selectedTileColor: colorInstitucional.withOpacity(0.15),
                onTap: () => _navegarA(context, 'Administradores', const AdminsPage()), 
              ),
              
              // 5. Lugares
              ListTile(
                leading: const Icon(Icons.place, color: Colors.grey),
                title: const Text('Lugares'),
                onTap: () => _navegarA(context, 'Lugares', const LugaresPage()),
              ),
              
              const Divider(),
              
              // 6. Inventario
              ListTile(
                leading: Icon(Icons.inventory, color: widget.paginaActual == 'Inventario' ? colorInstitucional : Colors.grey),
                title: Text(
                  'Inventario', 
                  style: TextStyle(
                    color: widget.paginaActual == 'Inventario' ? colorInstitucional : Colors.black, 
                    fontWeight: widget.paginaActual == 'Inventario' ? FontWeight.bold : FontWeight.normal
                  )
                ),
                selected: widget.paginaActual == 'Inventario',
                selectedTileColor: colorInstitucional.withOpacity(0.15),
                onTap: () => _navegarA(context, 'Inventario', const InventarioPage()),
              ),
              
              const Divider(),

              // 7. Cerrar Sesión
              ListTile(
                leading: Icon(Icons.exit_to_app_rounded, color: Colors.red.shade700),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
                onTap: () => _ejecutarCerrarSesion(context), 
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
        
        // Botón flotante inferior de configuraciones
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: null, 
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
            elevation: 3,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abriendo configuraciones...'), 
                  behavior: SnackBarBehavior.floating
                ),
              );
            },
            child: const Icon(Icons.settings),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool esPantallaAncha = constraints.maxWidth > 800;

        return Scaffold(
          key: _scaffoldKey, // <--- LLAVE CONECTADA AQUÍ PARA SEGURIDAD
          appBar: AppBar(
            backgroundColor: colorInstitucional,
            leadingWidth: 90,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Image.asset(
                'assets/uaqlogo.png', 
                height: 45, 
                fit: BoxFit.contain, 
                errorBuilder: (c, e, s) => const Icon(Icons.school, color: Colors.white)
              ),
            ),
            title: Text(
              widget.titulo, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)
            ),
            centerTitle: true,
            actions: esPantallaAncha ? null : [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          endDrawer: esPantallaAncha ? null : Drawer(child: _construirMenuLateral(context)),
          
          body: esPantallaAncha
              ? Row(
                  children: [
                    SizedBox(
                      width: 280, 
                      child: Material(
                        elevation: 4,
                        child: _construirMenuLateral(context),
                      ),
                    ),
                    Expanded(child: widget.cuerpo),
                  ],
                )
              : widget.cuerpo, 
        );
      },
    );
  }
}