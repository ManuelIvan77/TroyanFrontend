import 'package:flutter/material.dart';

// =====================================================================
// IMPORTACIÓN DEL WIDGET RESPONSIVO
// =====================================================================
import 'package:inventarioss/widgets/responsive_scaffold.dart';

class LugaresPage extends StatefulWidget {
  const LugaresPage({super.key});

  @override
  State<LugaresPage> createState() => _LugaresPageState();
}

class _LugaresPageState extends State<LugaresPage> {
  // Datos simulados para la tabla de lugares
  final List<Map<String, dynamic>> _datosLugares = [
    {
      'id': 'L-01',
      'nombre': 'Caballo de Troya',
      'descripcion': 'Almacén principal de instrumentos y equipo de audio.',
      'imagen': 'fachada_troya.jpg',
    },
    {
      'id': 'L-02',
      'nombre': 'Oficina',
      'descripcion': 'Área administrativa y atención a alumnos.',
      'imagen': null, // Sin imagen para probar el botón de subir
    },
    {
      'id': 'L-03',
      'nombre': 'Bodega',
      'descripcion': 'Resguardo de mobiliario y materiales pesados.',
      'imagen': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      titulo: 'Lugares',
      paginaActual: 'Lugares', // Para iluminar el botón en el menú
      
      cuerpo: Container(
        color: const Color(0xFFE5E5E5), // Fondo gris claro
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildTablaLugares(_datosLugares),
            ),
          ],
        ),
      ),
    );
  }

  // Generador de la tabla de lugares
  Widget _buildTablaLugares(List<Map<String, dynamic>> items) {
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
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            columnSpacing: 40,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Nombre del Lugar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              DataColumn(label: Text('Imagen', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  // Columna ID
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF666666),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        item['id'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Columna Nombre con estilo resaltado
                  DataCell(Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.w600))),
                  // Columna Descripción
                  DataCell(
                    SizedBox(
                      width: 250, // Limitamos el ancho para que el texto no se extienda infinitamente
                      child: Text(
                        item['descripcion'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ),
                  // Columna Imagen (Lógica condicional)
                  DataCell(
                    item['imagen'] != null
                        ? Row(
                            children: [
                              const Icon(Icons.image, size: 20, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(item['imagen'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: () {
                              // Aquí iría la lógica para abrir la galería o cámara
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Abriendo galería para ${item['nombre']}...'))
                              );
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text(
                              'Subir imagen',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
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