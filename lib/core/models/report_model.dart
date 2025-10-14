import '../stubs/firebase_stubs.dart';

/// Status for user reports
enum ReportStatus {
  pending,
  inProgress,
  resolved,
  dismissed
}

/// Model representing a user report
class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? details;
  final List<String> evidenceUrls;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.details,
    required this.evidenceUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String,
      reason: json['reason'] as String,
      details: json['details'] as String?,
      evidenceUrls: List<String>.from(json['evidenceUrls'] ?? []),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${json['status']}',
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      if (details != null) 'details': details,
      'evidenceUrls': evidenceUrls,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updates
  UserReport copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    String? details,
    List<String>? evidenceUrls,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserReport{id: $id, reporterId: $reporterId, reportedUserId: $reportedUserId, '
           'reason: $reason, status: $status}';
  }
}
