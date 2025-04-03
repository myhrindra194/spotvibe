import 'package:cloud_firestore/cloud_firestore.dart';

class Spot {
  final String? id;
  final String name;
  final String category;
  final GeoPoint location;
  final String specialty;
  final String? imageBase64; // Changé de imagePath à imageBase64
  final DateTime createdAt;
  final bool isVisited;
  final DateTime? visitDate;
  final int? rating;
  final String? comment;
  final String userUid;

  Spot({
    this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.specialty,
    this.imageBase64,
    required this.createdAt,
    this.isVisited = false,
    this.visitDate,
    this.rating,
    this.comment,
    required this.userUid,
  });

  factory Spot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Spot(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      specialty: data['specialty'] ?? '',
      imageBase64: data['imageBase64'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVisited: data['isVisited'] ?? false,
      visitDate: data['visitDate']?.toDate(),
      rating: data['rating'],
      comment: data['comment'],
      userUid: data['userUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'specialty': specialty,
      'imageBase64': imageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVisited': isVisited,
      'visitDate': visitDate != null ? Timestamp.fromDate(visitDate!) : null,
      'rating': rating,
      'comment': comment,
      'userUid': userUid,
    };
  }

  Spot copyWith({
    String? id,
    String? name,
    String? category,
    GeoPoint? location,
    String? specialty,
    String? imageBase64,
    DateTime? createdAt,
    bool? isVisited,
    DateTime? visitDate,
    int? rating,
    String? comment,
    String? userUid,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      specialty: specialty ?? this.specialty,
      imageBase64: imageBase64 ?? this.imageBase64,
      createdAt: createdAt ?? this.createdAt,
      isVisited: isVisited ?? this.isVisited,
      visitDate: visitDate ?? this.visitDate,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      userUid: userUid ?? this.userUid,
    );
  }
}
