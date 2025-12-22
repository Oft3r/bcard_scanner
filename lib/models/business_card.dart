class BusinessCard {
  final String id;
  final String name;
  final String title;
  final String company;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String imagePath;
  final String category;
  final DateTime scanDate;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final int colorIndex;

  BusinessCard({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.phone,
    required this.email,
    required this.website,
    required this.address,
    required this.imagePath,
    required this.category,
    required this.scanDate,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.colorIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'company': company,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'imagePath': imagePath,
      'category': category,
      'scanDate': scanDate.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'colorIndex': colorIndex,
    };
  }

  factory BusinessCard.fromMap(Map<String, dynamic> map) {
    return BusinessCard(
      id: map['id'],
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      address: map['address'] ?? '',
      imagePath: map['imagePath'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      scanDate: DateTime.parse(map['scanDate']),
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      latitude: map['latitude'],
      longitude: map['longitude'],
      colorIndex: map['colorIndex'] ?? 0,
    );
  }

  BusinessCard copyWith({
    String? id,
    String? name,
    String? title,
    String? company,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? imagePath,
    String? category,
    DateTime? scanDate,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    int? colorIndex,
  }) {
    return BusinessCard(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      scanDate: scanDate ?? this.scanDate,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}