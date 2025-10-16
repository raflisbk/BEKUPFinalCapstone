// Models for Indonesia Tourism functionality
import 'package:flutter/foundation.dart';

/// Indonesian Province model
class IndonesianProvince {
  final String id;
  final String name;
  final String code;
  final String capital;
  final List<String> popularCities;
  final List<String> tourismHighlights;

  const IndonesianProvince({
    required this.id,
    required this.name,
    required this.code,
    required this.capital,
    required this.popularCities,
    required this.tourismHighlights,
  });

  /// Create from Map (from service data)
  factory IndonesianProvince.fromMap(Map<String, dynamic> map) {
    return IndonesianProvince(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      capital: map['capital'] ?? '',
      popularCities: List<String>.from(map['popular_cities'] ?? []),
      tourismHighlights: List<String>.from(map['tourism_highlights'] ?? []),
    );
  }

  /// Convert to Map (for service calls)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'capital': capital,
      'popular_cities': popularCities,
      'tourism_highlights': tourismHighlights,
    };
  }

  /// Create copy with modified values
  IndonesianProvince copyWith({
    String? id,
    String? name,
    String? code,
    String? capital,
    List<String>? popularCities,
    List<String>? tourismHighlights,
  }) {
    return IndonesianProvince(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      capital: capital ?? this.capital,
      popularCities: popularCities ?? this.popularCities,
      tourismHighlights: tourismHighlights ?? this.tourismHighlights,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IndonesianProvince &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.capital == capital &&
        listEquals(other.popularCities, popularCities) &&
        listEquals(other.tourismHighlights, tourismHighlights);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        code.hashCode ^
        capital.hashCode ^
        popularCities.hashCode ^
        tourismHighlights.hashCode;
  }

  @override
  String toString() {
    return 'IndonesianProvince(id: $id, name: $name, code: $code, capital: $capital)';
  }

  // Static instances for popular provinces
  static const IndonesianProvince jawaBarat = IndonesianProvince(
    id: 'jawa-barat',
    name: 'Jawa Barat',
    code: 'JB',
    capital: 'Bandung',
    popularCities: ['Bandung', 'Bogor', 'Depok', 'Bekasi', 'Cirebon'],
    tourismHighlights: ['Tangkuban Perahu', 'Kawah Putih', 'Braga Street', 'Situ Patenggang'],
  );

  static const IndonesianProvince dkiJakarta = IndonesianProvince(
    id: 'dki-jakarta',
    name: 'DKI Jakarta',
    code: 'JK',
    capital: 'Jakarta',
    popularCities: ['Jakarta Pusat', 'Jakarta Selatan', 'Jakarta Barat', 'Jakarta Utara', 'Jakarta Timur'],
    tourismHighlights: ['Monas', 'Kota Tua', 'Ancol', 'Ragunan Zoo'],
  );

  static const IndonesianProvince jawaTengah = IndonesianProvince(
    id: 'jawa-tengah',
    name: 'Jawa Tengah',
    code: 'JT',
    capital: 'Semarang',
    popularCities: ['Semarang', 'Solo', 'Yogyakarta', 'Magelang', 'Tegal'],
    tourismHighlights: ['Borobudur', 'Prambanan', 'Lawang Sewu', 'Dieng Plateau'],
  );

  static const IndonesianProvince jawaTimur = IndonesianProvince(
    id: 'jawa-timur',
    name: 'Jawa Timur',
    code: 'JI',
    capital: 'Surabaya',
    popularCities: ['Surabaya', 'Malang', 'Kediri', 'Madiun', 'Jember'],
    tourismHighlights: ['Mount Bromo', 'Ijen Crater', 'Tumpak Sewu', 'Jatim Park'],
  );

  static const IndonesianProvince bali = IndonesianProvince(
    id: 'bali',
    name: 'Bali',
    code: 'BA',
    capital: 'Denpasar',
    popularCities: ['Denpasar', 'Ubud', 'Sanur', 'Kuta', 'Canggu'],
    tourismHighlights: ['Tanah Lot', 'Uluwatu', 'Tegallalang Rice Terraces', 'Mount Batur'],
  );

  /// Get all predefined provinces
  static List<IndonesianProvince> get allProvinces => [
        jawaBarat,
        dkiJakarta,
        jawaTengah,
        jawaTimur,
        bali,
      ];
}

/// Tourism Category model
class TourismCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final List<String> examples;

  const TourismCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
  });

  /// Create from Map (from service data)
  factory TourismCategory.fromMap(Map<String, dynamic> map) {
    return TourismCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '',
      examples: List<String>.from(map['examples'] ?? []),
    );
  }

  /// Convert to Map (for service calls)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'examples': examples,
    };
  }

  /// Create copy with modified values
  TourismCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    List<String>? examples,
  }) {
    return TourismCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      examples: examples ?? this.examples,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourismCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.color == color &&
        listEquals(other.examples, examples);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        examples.hashCode;
  }

  @override
  String toString() {
    return 'TourismCategory(id: $id, name: $name, description: $description)';
  }

  // Static instances for popular categories
  static const TourismCategory wisataAlam = TourismCategory(
    id: 'wisata-alam',
    name: 'Wisata Alam',
    description: 'Destinasi alam seperti gunung, danau, hutan, dan taman nasional',
    icon: 'nature_people',
    color: '#4CAF50',
    examples: ['Gunung Bromo', 'Danau Toba', 'Raja Ampat', 'Taman Nasional Komodo'],
  );

  static const TourismCategory wisataPantai = TourismCategory(
    id: 'wisata-pantai',
    name: 'Wisata Pantai',
    description: 'Pantai-pantai indah di seluruh Indonesia',
    icon: 'beach_access',
    color: '#2196F3',
    examples: ['Kuta Beach', 'Sanur Beach', 'Gili Trawangan', 'Pink Beach'],
  );

  static const TourismCategory wisataBudaya = TourismCategory(
    id: 'wisata-budaya',
    name: 'Wisata Budaya',
    description: 'Destinasi bersejarah dan budaya Indonesia',
    icon: 'account_balance',
    color: '#FF9800',
    examples: ['Borobudur', 'Prambanan', 'Keraton Yogyakarta', 'Taman Mini'],
  );

  static const TourismCategory wisataKuliner = TourismCategory(
    id: 'wisata-kuliner',
    name: 'Wisata Kuliner',
    description: 'Destinasi untuk menikmati kuliner khas Indonesia',
    icon: 'restaurant',
    color: '#F44336',
    examples: ['Malioboro Street', 'Braga Street', 'Pasar Santa', 'Jalan Alor'],
  );

  static const TourismCategory wisataGunung = TourismCategory(
    id: 'wisata-gunung',
    name: 'Wisata Gunung',
    description: 'Gunung-gunung untuk hiking dan pendakian',
    icon: 'terrain',
    color: '#795548',
    examples: ['Gunung Rinjani', 'Gunung Semeru', 'Gunung Merapi', 'Gunung Batur'],
  );

  static const TourismCategory wisataReligi = TourismCategory(
    id: 'wisata-religi',
    name: 'Wisata Religi',
    description: 'Tempat-tempat ibadah dan ziarah',
    icon: 'place_of_worship',
    color: '#9C27B0',
    examples: ['Masjid Istiqlal', 'Candi Borobudur', 'Wihara Dharma Bhakti', 'Gereja Katedral'],
  );

  static const TourismCategory wisataModern = TourismCategory(
    id: 'wisata-modern',
    name: 'Wisata Modern',
    description: 'Destinasi modern seperti mall, taman hiburan, dan gedung pencakar langit',
    icon: 'location_city',
    color: '#607D8B',
    examples: ['Ancol', 'Dufan', 'Central Park', 'Sky Bridge'],
  );

  static const TourismCategory ecoTourism = TourismCategory(
    id: 'eco-tourism',
    name: 'Eco Tourism',
    description: 'Wisata ramah lingkungan dan konservasi',
    icon: 'eco',
    color: '#8BC34A',
    examples: ['Taman Nasional Ujung Kulon', 'Bukit Lawang', 'Tangkoko Nature Reserve'],
  );

  /// Get all predefined categories
  static List<TourismCategory> get allCategories => [
        wisataAlam,
        wisataPantai,
        wisataBudaya,
        wisataKuliner,
        wisataGunung,
        wisataReligi,
        wisataModern,
        ecoTourism,
      ];
}