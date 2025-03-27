// tradition_model.dart
class TraditionModel {
  final String id;
  final String name;
  final String description;
  final int points;
  final String location;
  final Map<String, double> coordinates;
  final String imagePath;
  final bool isSeasonal;
  final String? season;

  TraditionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.location,
    required this.coordinates,
    required this.imagePath,
    this.isSeasonal = false,
    this.season,
  });

  // Create from a map (e.g., from Firestore)
  factory TraditionModel.fromMap(Map<String, dynamic> map) {
    return TraditionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      location: map['location'] ?? '',
      coordinates: Map<String, double>.from(map['coordinates'] ?? {}),
      imagePath: map['image'] ?? 'assets/traditions/default.jpg',
      isSeasonal: map['seasonal'] ?? false,
      season: map['season'],
    );
  }

  // Convert to map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'location': location,
      'coordinates': coordinates,
      'image': imagePath,
      'seasonal': isSeasonal,
      'season': season,
    };
  }
}