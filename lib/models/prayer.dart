import 'package:cloud_firestore/cloud_firestore.dart';

class Prayer {
  final String id;
  final String title;
  final String message;
  final String userId;
  final String status;
  final DateTime date;

  Prayer({
    required this.id,
    required this.title,
    required this.message,
    required this.userId,
    required this.status,
    required this.date,
  });

  factory Prayer.fromFirestore(String id, Map<String, dynamic> data) {
    return Prayer(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
} 