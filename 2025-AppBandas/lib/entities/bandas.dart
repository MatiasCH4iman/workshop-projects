import 'package:cloud_firestore/cloud_firestore.dart';

class Banda {
  final String? id;
  final String nombre;
  final String integrantes;
  final String? image;
  final String? origen;
  final String? descripcion;
  final List<String> favoritedBy; 

  Banda({
    this.id,
    required this.nombre,
    required this.integrantes,
    this.image,
    this.origen,
    this.descripcion,
    this.favoritedBy = const [],
  });

  Banda copyWith({
    String? id,
    String? nombre,
    String? integrantes,
    String? image,
    String? origen,
    String? descripcion,
    List<String>? favoritedBy,
  }) {
    return Banda(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      integrantes: integrantes ?? this.integrantes,
      image: image ?? this.image,
      origen: origen ?? this.origen,
      descripcion: descripcion ?? this.descripcion,
      favoritedBy: favoritedBy ?? this.favoritedBy,
    );
  }

  bool isFavoritedBy(String uid) => favoritedBy.contains(uid);

  /// Convierte el objeto Banda en un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'integrantes': integrantes,
      'image': image,
      'origen': origen,
      'descripcion': descripcion,
      'favoritedBy': favoritedBy,
    };
  }

  static Banda fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    if (data == null) {
      return Banda(
        id: snapshot.id,
        nombre: 'Desconocido',
        integrantes: 'N/A',
      );
    }

    return Banda(
      id: snapshot.id,
      nombre: data['nombre'] ?? '',
      integrantes: data['integrantes'] ?? '',
      image: data['image'],
      origen: data['origen'],
      descripcion: data['descripcion'],
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
    );
  }
}
