class Spot {
  String? id;
  String category;
  String name;
  String location;
  String specialty;
  String comment;
  double rating;
  bool visited;
  DateTime? visitedDate;
  String imageUrl;

  Spot({
    this.id,
    required this.category,
    required this.name,
    required this.location,
    required this.specialty,
    required this.comment,
    required this.rating,
    required this.visited,
    this.visitedDate,
    required this.imageUrl,
  });

  factory Spot.fromMap(Map<String, dynamic> data, String id) {
    return Spot(
      id: id,
      category: data['category'],
      name: data['name'],
      location: data['location'],
      specialty: data['specialty'],
      comment: data['comment'],
      rating: data['rating'],
      visited: data['visited'],
      visitedDate: data['visitedDate']?.toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'name': name,
      'location': location,
      'specialty': specialty,
      'comment': comment,
      'rating': rating,
      'visited': visited,
      'visitedDate': visitedDate,
      'imageUrl': imageUrl,
    };
  }
}
