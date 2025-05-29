import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import '../services/firestore_service.dart';

class PrayerApprovalScreen extends StatefulWidget {
  @override
  _PrayerApprovalScreenState createState() => _PrayerApprovalScreenState();
}

class _PrayerApprovalScreenState extends State<PrayerApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isPastor = false;

  @override
  void initState() {
    super.initState();
    _checkPastorRole();
  }

  Future<void> _checkPastorRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isPastor = userDoc.data()?['role'] == 'pastor';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPastor) {
      return Scaffold(
        appBar: AppBar(title: Text('Prayer Requests')),
        body: Center(
          child: Text('Only pastors can access this section'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Prayer Request Approval'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('prayerRequests')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending prayer requests',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ExpansionTile(
                  title: Text(
                    data['title'] ?? 'Untitled Request',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'From: ${data['userName'] ?? 'Anonymous'}',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['description'] ?? 'No description provided',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.check),
                                label: Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  await _firestore
                                      .collection('prayerRequests')
                                      .doc(request.id)
                                      .update({
                                    'status': 'approved',
                                    'approvedAt': FieldValue.serverTimestamp(),
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Prayer request approved'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.close),
                                label: Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  await _firestore
                                      .collection('prayerRequests')
                                      .doc(request.id)
                                      .update({
                                    'status': 'rejected',
                                    'rejectedAt': FieldValue.serverTimestamp(),
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Prayer request rejected'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 