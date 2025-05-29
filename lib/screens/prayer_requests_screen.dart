import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
//import 'package:flutter/foundation.dart' show kIsWeb;
//import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class PrayerRequestsScreen extends StatefulWidget {
  @override
  _PrayerRequestsScreenState createState() => _PrayerRequestsScreenState();
}

class _PrayerRequestsScreenState extends State<PrayerRequestsScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _editingPrayerId;
  String? _editingImageUrl;
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _isPastor = false;

  @override
  void initState() {
    super.initState();
    _checkPastorRole();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkPastorRole() async {
    if (user?.uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists && userDoc['role'] == 'pastor') {
        setState(() {
          _isPastor = true;
          // Update TabController length when pastor role is confirmed
          _tabController.dispose();
          _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await Provider.of<StorageService>(context, listen: false)
            .uploadPrayerImage(_selectedImage!);
      }

      await _firestore.collection('prayerRequests').add({
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Anonymous',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prayer request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting prayer request'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _editingPrayerId = null;
      _editingImageUrl = null;
    });
  }

  void _editPrayer(Map<String, dynamic> prayer) {
    setState(() {
      _editingPrayerId = prayer['id'];
      _titleController.text = prayer['title'];
      _descriptionController.text = prayer['description'];
      _editingImageUrl = prayer['imageUrl'];
    });
  }

  Future<void> _deletePrayer(String prayerId) async {
    try {
      await _firestore.collection('prayerRequests').doc(prayerId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prayer request deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting prayer request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData iconData;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        label = 'Approved';
        break;
      case 'rejected':
        chipColor = Colors.red;
        iconData = Icons.cancel;
        label = 'Rejected';
        break;
      default:
        chipColor = Colors.orange;
        iconData = Icons.hourglass_empty;
        label = 'Pending';
    }

    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 16),
      label: Text(label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
    );
  }

  Widget _buildPrayerRequestCard(Map<String, dynamic> data, String docId, {bool isPastor = false, bool showApproval = false}) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: data['description'] ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prayer copied!'), backgroundColor: Colors.orange[700]),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20, left: 12, right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[50]!, Colors.orange[100]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['title'] ?? '',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[700]),
                    ),
                  ),
                  if (isPastor) ...[
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                      onPressed: () => _editPrayerRequest(docId, data),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePrayerRequest(docId),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
              Text(
                data['description'] ?? '',
                style: TextStyle(fontSize: 16, color: Colors.brown[600]),
              ),
              if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrayerRequestDetailScreen(data: data),
                      ),
                    );
                  },
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.orange[700], size: 18),
                  SizedBox(width: 4),
                  Text('By: ${data['userName'] ?? 'Anonymous'}', style: TextStyle(color: Colors.brown[500], fontSize: 14)),
                  Spacer(),
                  if (showApproval)
                    Row(
                      children: [
                    ElevatedButton(
                      onPressed: () => _approvePrayerRequest(docId),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Approve'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _confirmRejectPrayerRequest(docId),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text('Reject'),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange[700], size: 16),
                  SizedBox(width: 4),
                  Text(
                    data['timestamp'] != null ? _formatDate(data['timestamp']) : '',
                    style: TextStyle(fontSize: 12, color: Colors.brown[400]),
                  ),
                  Spacer(),
                  _buildStatusChip(data['status'] ?? ''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editPrayerRequest(String docId, Map<String, dynamic> data) {
    // Show a dialog or bottom sheet to edit the request
  }

  void _deletePrayerRequest(String docId) async {
    await FirebaseFirestore.instance.collection('prayerRequests').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prayer request deleted')));
  }

  void _approvePrayerRequest(String docId) async {
    await FirebaseFirestore.instance.collection('prayerRequests').doc(docId).update({'status': 'approved'});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prayer request approved')));
  }

  void _confirmRejectPrayerRequest(String docId) async {
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Prayer Request'),
        content: Text('Are you sure you want to reject this prayer request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldReject == true) {
      _rejectPrayerRequest(docId);
    }
  }

  void _rejectPrayerRequest(String docId) async {
    await FirebaseFirestore.instance.collection('prayerRequests').doc(docId).update({'status': 'rejected'});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prayer request rejected')));
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openAddPrayerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
                            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddPrayerRequestForm(),
      ),
    );
  }

  void _openImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange[700],
          elevation: 0,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _tabController.index == 0
                      ? 'Community Prayers'
                      : _tabController.index == 1 && _isPastor
                          ? 'Pending Approval'
                          : 'My Requests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_tabController.index == 0)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  icon: Icon(Icons.person, color: Colors.orange[700], size: 20),
                  label: Text(_isPastor ? 'Pending' : 'My Requests', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                  onPressed: () => _tabController.animateTo(_isPastor ? 1 : 1),
                ),
              if (_tabController.index == 1 && _isPastor)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  icon: Icon(Icons.people, color: Colors.orange[700], size: 20),
                  label: Text('Community', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                  onPressed: () => _tabController.animateTo(0),
                ),
              if (_tabController.index == (_isPastor ? 2 : 1))
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  icon: Icon(Icons.people, color: Colors.orange[700], size: 20),
                  label: Text(_isPastor ? 'Community' : 'Community', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                  onPressed: () => _tabController.animateTo(0),
                ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: TabBarView(
          controller: _tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            // Community Prayers Tab
            _buildCommunityPrayers(),
            if (_isPastor) _buildUnapprovedRequests(),
            // My Requests Tab
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('prayerRequests').where('userId', isEqualTo: user?.uid).orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data?.docs ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Text('No prayer requests yet', style: TextStyle(fontSize: 18, color: Colors.brown[600])),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                Icon(Icons.favorite, color: Colors.orange[700]),
                                    SizedBox(width: 8),
                                    Expanded(
                                                child: Text(
                                    data['title'] ?? '',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[700]),
                                                ),
                                              ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                              data['description'] ?? '',
                              style: TextStyle(fontSize: 16, color: Colors.brown[600]),
                            ),
                            if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
                              SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrayerRequestDetailScreen(data: data),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'],
                                    height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                                SizedBox(height: 8),
                                Text(
                              'Status: \\${data['status'] ?? 'pending'}',
                              style: TextStyle(fontSize: 12, color: Colors.brown[400]),
                            ),
                            if (data['timestamp'] != null)
                              Text(
                                _formatDate(data['timestamp']),
                                style: TextStyle(fontSize: 12, color: Colors.brown[400]),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                backgroundColor: Colors.orange[700],
                icon: Icon(Icons.add),
                label: Text('Add Request'),
                onPressed: _openAddPrayerModal,
              )
            : null,
      ),
    );
  }

  Widget _buildCommunityPrayers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('prayerRequests')
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return Center(child: Text('No approved prayer requests yet.'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;
            return _buildPrayerRequestCard(data, docId, isPastor: _isPastor);
          },
        );
      },
    );
  }

  Widget _buildUnapprovedRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('prayerRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return Center(child: Text('No unapproved requests.'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;
            return _buildPrayerRequestCard(data, docId, isPastor: true, showApproval: true);
          },
        );
      },
    );
  }
}

class _AddPrayerRequestForm extends StatefulWidget {
  @override
  State<_AddPrayerRequestForm> createState() => _AddPrayerRequestFormState();
}

class _AddPrayerRequestFormState extends State<_AddPrayerRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await Provider.of<StorageService>(context, listen: false)
            .uploadPrayerImage(_selectedImage!);
      }
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('prayerRequests').add({
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Anonymous',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prayer request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting prayer request'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Prayer Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[700])),
            SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.orange[50],
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.orange[50],
              ),
              maxLines: 4,
              validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.photo),
                  label: Text('Add Photo'),
                  onPressed: _pickImage,
                ),
                SizedBox(width: 12),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 48, width: 48, fit: BoxFit.cover),
                  ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitPrayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const PrayerRequestDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prayer Request Details'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      data['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 24),
            Text('Name: ${data['userName'] ?? 'Anonymous'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800])),
            SizedBox(height: 8),
            if (data['phone'] != null)
              Text('Phone: ${data['phone']}', style: TextStyle(fontSize: 16, color: Colors.brown[700])),
            if (data['village'] != null)
              Text('Village: ${data['village']}', style: TextStyle(fontSize: 16, color: Colors.brown[700])),
            SizedBox(height: 16),
            Text('Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[700])),
            SizedBox(height: 8),
            Text(data['description'] ?? '', style: TextStyle(fontSize: 16, color: Colors.brown[800], height: 1.5)),
            SizedBox(height: 16),
            if (data['status'] != null)
              Row(
                children: [
                  Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
                  Text(data['status'], style: TextStyle(color: data['status'] == 'approved' ? Colors.green : (data['status'] == 'rejected' ? Colors.red : Colors.orange[700]), fontWeight: FontWeight.bold)),
                ],
            ),
          ],
        ),
      ),
    );
  }
} 