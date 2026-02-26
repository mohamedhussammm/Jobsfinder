/// Location data stored as JSON in the backend
class LocationData {
  final String? address;
  final double? lat;
  final double? lng;

  LocationData({this.address, this.lat, this.lng});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address']?.toString(),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {'address': address, 'lat': lat, 'lng': lng};
}

/// Event model - represents job/shift events created by companies
class EventModel {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final LocationData? location;
  final DateTime startTime;
  final DateTime endTime;
  final int? capacity;
  final String? imagePath;
  final String
  status; // 'draft', 'pending', 'published', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;

  // ─── New fields ─────────────────────────────
  final double? salary;
  final String? requirements;
  final String? benefits;
  final String? contactEmail;
  final String? contactPhone;
  final List<String> tags;
  final bool isUrgent;
  final String? companyName;
  final String? companyLogo;

  EventModel({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.capacity,
    this.imagePath,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.salary,
    this.requirements,
    this.benefits,
    this.contactEmail,
    this.contactPhone,
    this.tags = const [],
    this.isUrgent = false,
    this.companyName,
    this.companyLogo,
  });

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isPublished => status == 'published';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isDraft => status == 'draft';

  // Time helpers
  bool get isUpcoming => endTime.isAfter(DateTime.now());
  bool get isOngoing =>
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    // companyId may be a populated object
    final companyRaw = json['companyId'] ?? json['company_id'];
    final String companyId;
    String? companyName;
    String? companyLogo;
    if (companyRaw is Map) {
      companyId = (companyRaw['_id'] ?? companyRaw['id'] ?? '').toString();
      companyName = companyRaw['name']?.toString();
      companyLogo = companyRaw['logoPath']?.toString();
    } else {
      companyId = (companyRaw ?? '').toString();
    }

    // location may be null or an object
    LocationData? location;
    final locRaw = json['location'];
    if (locRaw is Map<String, dynamic>) {
      location = LocationData.fromJson(locRaw);
    }

    // categoryId may be a populated object
    final catRaw = json['categoryId'] ?? json['category_id'];
    String? categoryId;
    String? categoryName;
    String? categoryIcon;
    if (catRaw is Map) {
      categoryId = (catRaw['_id'] ?? catRaw['id'])?.toString();
      categoryName = catRaw['name']?.toString();
      categoryIcon = catRaw['icon']?.toString();
    } else {
      categoryId = catRaw?.toString();
    }

    // tags
    final tagsRaw = json['tags'];
    final List<String> tags = [];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t != null) tags.add(t.toString());
      }
    }

    return EventModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      companyId: companyId,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      location: location,
      startTime: parseDate(json['startTime'] ?? json['start_time']),
      endTime: parseDate(json['endTime'] ?? json['end_time']),
      capacity: json['capacity'] != null
          ? (json['capacity'] as num).toInt()
          : null,
      imagePath:
          json['imagePath']?.toString() ?? json['image_path']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      salary: json['salary'] != null
          ? (json['salary'] as num).toDouble()
          : null,
      requirements: json['requirements']?.toString(),
      benefits: json['benefits']?.toString(),
      contactEmail:
          json['contactEmail']?.toString() ?? json['contact_email']?.toString(),
      contactPhone:
          json['contactPhone']?.toString() ?? json['contact_phone']?.toString(),
      tags: tags,
      isUrgent: (json['isUrgent'] ?? json['is_urgent'] ?? false) == true,
      companyName: companyName,
      companyLogo: companyLogo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'title': title,
    'description': description,
    'location': location?.toJson(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'capacity': capacity,
    'imagePath': imagePath,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'categoryId': categoryId,
    'salary': salary,
    'requirements': requirements,
    'benefits': benefits,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'tags': tags,
    'isUrgent': isUrgent,
  };

  EventModel copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    LocationData? location,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    String? imagePath,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    double? salary,
    String? requirements,
    String? benefits,
    String? contactEmail,
    String? contactPhone,
    List<String>? tags,
    bool? isUrgent,
    String? companyName,
    String? companyLogo,
  }) {
    return EventModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      salary: salary ?? this.salary,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      tags: tags ?? this.tags,
      isUrgent: isUrgent ?? this.isUrgent,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
    );
  }

  @override
  String toString() => 'EventModel($id, $title, $status)';
}

/// Extension to provide UI-expected properties
extension EventModelExtensions on EventModel {
  String get company => companyName ?? 'Company';
  DateTime get eventDate => startTime;
  int get applicants => 0;
  double get rating => 0.0;
}

/// Extension for LocationData
extension LocationDataExtensions on LocationData {
  String get city {
    if (address != null && address!.isNotEmpty) {
      final parts = address!.split(',');
      if (parts.length > 1) {
        return parts[parts.length - 2].trim();
      }
      return address!;
    }
    return 'Unknown';
  }
}
