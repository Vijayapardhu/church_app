class Inspiration {
  final String quote;
  final String audioUrl;

  Inspiration({required this.quote, required this.audioUrl});

  factory Inspiration.fromFirestore(Map<String, dynamic> data) {
    return Inspiration(
      quote: data['quote'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
    );
  }
} 