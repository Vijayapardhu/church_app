import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItem {
  final String id;
  final String title;
  final DateTime date;
  final String imageUrl;

  GalleryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
  });

  factory GalleryItem.fromFirestore(String id, Map<String, dynamic> data) {
    return GalleryItem(
      id: id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }
} 