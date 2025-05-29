import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class DailyInspirationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: Provider.of<FirestoreService>(context).getDailyInspiration(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading inspiration: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(
              child: Text('No inspiration available'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Inspiration',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.brown[600],
                            height: 1.5,
                          ),
                        ),
                        if (data['verse'] != null) ...[
                          SizedBox(height: 16),
                          Text(
                            '- ${data['verse']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.brown[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 