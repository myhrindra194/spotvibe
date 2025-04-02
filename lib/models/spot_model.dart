import 'package:cloud_firestore/cloud_firestore.dart';

class Spot {
  final String? id;
  final String name;
  final String category;
  final GeoPoint location;
  final String specialty;
  final String? imagePath;
  final DateTime createdAt;
  final bool isVisited;
  final DateTime? visitDate;
  final int? rating;
  final String? comment;

  Spot({
    this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.specialty,
    this.imagePath,
    required this.createdAt,
    this.isVisited = false,
    this.visitDate,
    this.rating,
    this.comment,
  });

  factory Spot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Spot(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      specialty: data['specialty'] ?? '',
      imagePath: data['imagePath'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVisited: data['isVisited'] ?? false,
      visitDate: data['visitDate']?.toDate(),
      rating: data['rating'],
      comment: data['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'specialty': specialty,
      'imagePath': imagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVisited': isVisited,
      'visitDate': visitDate != null ? Timestamp.fromDate(visitDate!) : null,
      'rating': rating,
      'comment': comment,
    };
  }

  Spot copyWith({
    String? id,
    String? name,
    String? category,
    GeoPoint? location,
    String? specialty,
    String? imagePath,
    DateTime? createdAt,
    bool? isVisited,
    DateTime? visitDate,
    int? rating,
    String? comment,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      specialty: specialty ?? this.specialty,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isVisited: isVisited ?? this.isVisited,
      visitDate: visitDate ?? this.visitDate,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }
}
