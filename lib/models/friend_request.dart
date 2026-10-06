import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a friend request.
enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  String get value => name;

  static FriendRequestStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      case 'pending':
      default:
        return FriendRequestStatus.pending;
    }
  }
}

/// Represents an asynchronous friend request stored in Firestore `friend_requests/{id}`.
class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final String fromName;
  final String fromEmail;
  final String toName;
  final String toEmail;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.fromName = '',
    this.fromEmail = '',
    this.toName = '',
    this.toEmail = '',
  });

  String get fromInitials {
    if (fromName.trim().isNotEmpty) {
      final parts = fromName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fromName[0].toUpperCase();
    }
    if (fromEmail.isNotEmpty) {
      return fromEmail[0].toUpperCase();
    }
    return '?';
  }

  FriendRequest copyWith({
    String? id,
    String? fromUid,
    String? toUid,
    FriendRequestStatus? status,
    DateTime? createdAt,
    String? fromName,
    String? fromEmail,
    String? toName,
    String? toEmail,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      toName: toName ?? this.toName,
      toEmail: toEmail ?? this.toEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUid': fromUid,
      'toUid': toUid,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toName': toName,
      'toEmail': toEmail,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return FriendRequest(
      id: id ?? (json['id'] as String? ?? ''),
      fromUid: json['fromUid'] as String? ?? '',
      toUid: json['toUid'] as String? ?? '',
      status: FriendRequestStatus.fromString(json['status'] as String?),
      createdAt: parsedDate,
      fromName: json['fromName'] as String? ?? '',
      fromEmail: json['fromEmail'] as String? ?? '',
      toName: json['toName'] as String? ?? '',
      toEmail: json['toEmail'] as String? ?? '',
    );
  }
}
