import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

/// Location data stored as JSONB in Supabase
@JsonSerializable()
class LocationData {
  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  LocationData({this.address, this.lat, this.lng});

  factory LocationData.fromJson(Map<String, dynamic> json) =>
      _$LocationDataFromJson(json);
  Map<String, dynamic> toJson() => _$LocationDataToJson(this);
}

/// Event model - represents job/shift events created by companies
@JsonSerializable()
class EventModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'company_id')
  final String companyId;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'location')
  final LocationData? location;

  @JsonKey(name: 'start_time')
  final DateTime startTime;

  @JsonKey(name: 'end_time')
  final DateTime endTime;

  @JsonKey(name: 'capacity')
  final int? capacity;

  @JsonKey(name: 'image_path')
  final String? imagePath;

  @JsonKey(name: 'status')
  final String status; // 'draft', 'pending', 'published', 'completed', 'cancelled'

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Category fields — populated via JOIN (categories!category_id)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? categoryId;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? categoryName;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? categoryIcon;

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
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);
  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  @override
  String toString() => 'EventModel($id, $title, $status)';
}

/// Extension to provide UI-expected properties
extension EventModelExtensions on EventModel {
  // Company name - placeholder until we implement proper company joins
  String get company =>
      'Company'; // Placeholder — populated via company join when available

  // Event date - simplified date field (uses startTime)
  DateTime get eventDate => startTime;

  // Number of applicants - placeholder until we implement counting
  int get applicants =>
      0; // Placeholder — counted from applications table when available

  // Rating - placeholder until we implement rating system
  double get rating =>
      0.0; // Placeholder — averaged from ratings table when available
}

/// Extension for LocationData
extension LocationDataExtensions on LocationData {
  // City extracted from address or placeholder
  String get city {
    if (address != null && address!.isNotEmpty) {
      // Try to extract city from address (simple approach)
      final parts = address!.split(',');
      if (parts.length > 1) {
        return parts[parts.length - 2].trim();
      }
      return address!;
    }
    return 'Unknown';
  }
}
