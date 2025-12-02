import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loginhome1/entities/bandas.dart';
import 'package:loginhome1/presentation/providers/bandas_provider.dart';

class AddScreen extends ConsumerStatefulWidget {
  static const String name = 'add_band_screen';
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController integrantesController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    integrantesController.dispose();
    imageController.dispose();
    originController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Añadir Banda"),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ingrese los datos de la banda'),
              const SizedBox(height: 20),

              _buildTextField(nombreController, 'Nombre'),
              const SizedBox(height: 20), 
              _buildTextField(integrantesController, 'Integrantes'),
              const SizedBox(height: 20),
              _buildTextField(imageController, 'Imagen URL'),
              const SizedBox(height: 20),
              _buildTextField(originController, 'Origen'),
              const SizedBox(height: 20),
              _buildTextField(descripcionController, 'Descripción'),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final nombre = nombreController.text.trim();
                  final integrantes = integrantesController.text.trim();

                  if (nombre.isEmpty || integrantes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Completar nombre e integrantes'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Crear la nueva banda
                  final nuevaBanda = Banda(
                    id: null, // Firestore lo asigna
                    nombre: nombre,
                    integrantes: integrantes,
                    image: imageController.text.trim(),
                    origen: originController.text.trim().isNotEmpty
                        ? originController.text.trim()
                        : null,
                    descripcion: descripcionController.text.trim(),
                  );

                  // Guardar en Firestore con Riverpod
                  await ref.read(bandasProvider.notifier).addBanda(nuevaBanda);

                  // Revisar si el State sigue montado
                  if (!mounted) return;

                  // Mostrar confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Banda "${nuevaBanda.nombre}" añadida correctamente'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Redirigir a la lista de bandas
                  GoRouter.of(context).go('/bandas');
                },
                child: const Text(
                  'Agregar',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
            ] ,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelText: label,
        ),
      ),
    );
  }
}
