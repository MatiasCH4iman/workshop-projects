import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loginhome1/presentation/providers/bandas_provider.dart';
import 'package:loginhome1/entities/bandas.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BandasScreen extends ConsumerWidget {
  static const String name = 'bandas_screen';
  const BandasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandas = ref.watch(bandasProvider);
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    // Mostrar favoritos primero
    final favoritos = bandas.where((b) => b.isFavoritedBy(uid)).toList();
    final noFavoritos = bandas.where((b) => !b.isFavoritedBy(uid)).toList();
    final bandasOrdenadas = [...favoritos, ...noFavoritos];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            final name = user?.displayName ?? 'Invitado';
            GoRouter.of(context).go(
              '/home',
              extra: {
                'userName': name,
                'direction': 'home',
              },
            );
          },
        ),
        title: const Text("Bandas"),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),

      // =================== LISTA DE BANDAS ===================
      body: ListView.builder(
        itemCount: bandasOrdenadas.length + 1,
        itemBuilder: (context, index) {
          if (index < bandasOrdenadas.length) {
            final banda = bandasOrdenadas[index];
            final isFavorite = banda.isFavoritedBy(uid);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isFavorite ? Colors.yellow[50] : null,
              child: ListTile(
                onTap: () => {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(banda.nombre),
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (banda.image != null && banda.image!.isNotEmpty)
                              Image.network(
                                banda.image!,
                                width: 100,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 100,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey, size: 50),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Integrantes: ${banda.integrantes}'),
                                  if (banda.origen != null)
                                    Text('Origen: ${banda.origen}'),
                                  if (banda.descripcion != null &&
                                      banda.descripcion!.isNotEmpty)
                                    Text('Descripción: ${banda.descripcion}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      );
                    },
                  )
                },
                leading: (banda.image != null && banda.image!.isNotEmpty)
                    ? Image.network(
                        banda.image!,
                        width: 70,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey, size: 50),
                        ),
                      )
                    : null,
                title: Text(
                  banda.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Integrantes: ${banda.integrantes}'),
                    if (banda.origen != null)
                      Text('Origen: ${banda.origen}'),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      tooltip: isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                      onPressed: () {
                        ref
                            .read(bandasProvider.notifier)
                            .toggleFavorite(banda.id!);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Editar banda',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final nombreController =
                                TextEditingController(text: banda.nombre);
                            final integrantesController =
                                TextEditingController(text: banda.integrantes);
                            final imageController = TextEditingController(
                                text: banda.image ?? '');
                            final origenController = TextEditingController(
                                text: banda.origen ?? '');
                            final descripcionController =
                                TextEditingController(
                                    text: banda.descripcion ?? '');

                            return AlertDialog(
                              title: const Text('Editar Banda'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nombreController,
                                      decoration: const InputDecoration(
                                          labelText: 'Nombre'),
                                    ),
                                    TextField(
                                      controller: integrantesController,
                                      decoration: const InputDecoration(
                                          labelText: 'Integrantes'),
                                    ),
                                    TextField(
                                      controller: imageController,
                                      decoration: const InputDecoration(
                                          labelText: 'Imagen URL'),
                                    ),
                                    TextField(
                                      controller: origenController,
                                      decoration: const InputDecoration(
                                          labelText: 'Origen'),
                                    ),
                                    TextField(
                                      controller: descripcionController,
                                      decoration: const InputDecoration(
                                          labelText: 'Descripción'),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final nombre = nombreController.text.trim();
                                    final integrantes =
                                        integrantesController.text.trim();

                                    if (nombre.isEmpty ||
                                        integrantes.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Nombre e integrantes son obligatorios'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    final nuevo = Banda(
                                      id: banda.id,
                                      nombre: nombre,
                                      integrantes: integrantes,
                                      image:
                                          imageController.text.trim().isEmpty
                                              ? null
                                              : imageController.text.trim(),
                                      origen:
                                          origenController.text.trim().isEmpty
                                              ? null
                                              : origenController.text.trim(),
                                      descripcion:
                                          descripcionController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : descripcionController.text
                                                  .trim(),
                                      favoritedBy: banda.favoritedBy,
                                    );

                                    ref
                                        .read(bandasProvider.notifier)
                                        .updateBanda(nuevo);

                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(bandasProvider.notifier)
                            .removeBanda(banda.id!);
                      },
                      tooltip: 'Eliminar banda',
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox(height: 80);
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).push('/add_band_screen');
        },
        tooltip: 'Agregar Banda',
        child: const Icon(Icons.add),
      ),
    );
  }
}
