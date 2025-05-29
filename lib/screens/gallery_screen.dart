import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import '../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isAdminOrPastor = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final role = doc['role'];
        setState(() {
          _isAdminOrPastor = role == 'admin' || role == 'pastor';
        });
      }
    }
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
          title: Text('Gallery'),
          backgroundColor: Colors.orange[700],
          elevation: 2,
        ),
        body: _buildGalleryBody(context),
        floatingActionButton: _isAdminOrPastor
            ? FloatingActionButton.extended(
                onPressed: () => _showUploadDialog(context),
                icon: Icon(Icons.upload),
                label: Text('Upload Images'),
                backgroundColor: Colors.orange[700],
              )
            : null,
      ),
    );
  }

  Widget _buildGalleryBody(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<FirestoreService>(context).getGalleryItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading gallery: ${snapshot.error}'),
          );
        }

        final items = snapshot.data?.docs ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.orange[300],
                ),
                SizedBox(height: 16),
                Text(
                  'No gallery items available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.brown[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Group items by date
        final Map<String, List<QueryDocumentSnapshot>> groupedItems = {};
        for (var item in items) {
          final data = item.data() as Map<String, dynamic>;
          final date = data['date']?.toDate() ?? DateTime.now();
          final dateKey = '${date.day}/${date.month}/${date.year}';
          
          if (!groupedItems.containsKey(dateKey)) {
            groupedItems[dateKey] = [];
          }
          groupedItems[dateKey]!.add(item);
        }

        // Sort dates in descending order
        final sortedDates = groupedItems.keys.toList()
          ..sort((a, b) {
            final dateA = _parseDate(a);
            final dateB = _parseDate(b);
            return dateB.compareTo(dateA);
          });

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final dateItems = groupedItems[dateKey]!;
            final firstItem = dateItems.first.data() as Map<String, dynamic>;
            final date = firstItem['date']?.toDate() ?? DateTime.now();
            final title = firstItem['title'] ?? '';
            final docId = dateItems.first.id;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDayGallery(context, dateItems, date),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 16),
                              Icon(Icons.title, color: Colors.orange[700], size: 20),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Colors.orange[700]),
                              SizedBox(width: 8),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                              
                              Spacer(),
                              Text(
                                '${dateItems.length} photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.brown[500],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.brown[500]),
                              if (_isAdminOrPastor) ...[
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.orange[700]),
                                  tooltip: 'Edit Gallery',
                                  onPressed: () => _showEditGalleryDialog(context, dateItems, docId, title, date),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Gallery',
                                  onPressed: () => _deleteGalleryEntry(context, docId),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: dateItems.length,
                              itemBuilder: (context, imageIndex) {
                                final item = dateItems[imageIndex].data() as Map<String, dynamic>;
                                final imageUrls = (item['imageUrls'] as List?)?.cast<String>() ?? [];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () => _showFullScreenGallery(context, imageUrls, imageIndex),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrls[imageIndex],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  void _showDayGallery(BuildContext context, List<QueryDocumentSnapshot> items, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[50]!, Colors.orange[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange[700]),
                    SizedBox(width: 8),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.brown[500]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index].data() as Map<String, dynamic>;
                    final imageUrls = (item['imageUrls'] as List?)?.cast<String>() ?? [];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InkWell(
                                onTap: () => _showImageDialog(context, item),
                                child: Stack(
                                  children: [
                                    for (final url in imageUrls)
                                      Positioned.fill(
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 32,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.download, color: Colors.orange[700]),
                                  onPressed: () => _downloadImage(context, imageUrls.first),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context, String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final fileName = imageUrl.split('/').last;
        
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: response.bodyBytes,
          mimeType: MimeType.jpeg,
        );

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[50]!, Colors.orange[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        for (final url in (item['imageUrls'] as List?)?.cast<String>() ?? [])
                          Positioned.fill(
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.download, color: Colors.orange[700]),
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadImage(context, (item['imageUrls'] as List?)?.cast<String>()?.first ?? '');
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    if (item['description'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        item['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUploadDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGalleryScreen(),
      ),
    );
  }

  void _deleteGalleryEntry(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('gallery').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery entry deleted'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting gallery: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditGalleryDialog(BuildContext context, List<QueryDocumentSnapshot> dateItems, String docId, String title, DateTime date) {
    final firstItem = dateItems.first.data() as Map<String, dynamic>;
    final imageUrlsRaw = firstItem['imageUrls'] ?? [firstItem['imageUrl'] ?? ''];
    final imageUrls = List<String>.from(imageUrlsRaw.map((e) => e.toString()));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGalleryScreen(
          docId: docId,
          initialTitle: title,
          initialDate: date,
          initialImageUrls: imageUrls,
        ),
      ),
    );
  }

  void _showFullScreenGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: _FullScreenGalleryView(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            onDownload: (url) => _downloadImage(context, url),
          ),
        );
      },
    );
  }
}

class EditGalleryScreen extends StatefulWidget {
  final String? docId;
  final String? initialTitle;
  final DateTime? initialDate;
  final List<String>? initialImageUrls;

  EditGalleryScreen({this.docId, this.initialTitle, this.initialDate, this.initialImageUrls});

  @override
  State<EditGalleryScreen> createState() => _EditGalleryScreenState();
}

class _EditGalleryScreenState extends State<EditGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime? _selectedDate;
  List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  Map<int, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _selectedDate = widget.initialDate;
    _existingImageUrls = List<String>.from(widget.initialImageUrls ?? []);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _newImages = picked;
      });
    }
  }

  Future<void> _saveGallery() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    setState(() => _isLoading = true);
    try {
      final urls = List<String>.from(_existingImageUrls);
      _uploadProgress.clear();
      for (int i = 0; i < _newImages.length; i++) {
        final image = _newImages[i];
        final ref = FirebaseStorage.instance
            .ref()
            .child('gallery')
            .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          uploadTask = ref.putFile(File(image.path));
        }
        uploadTask.snapshotEvents.listen((event) {
          setState(() {
            _uploadProgress[i] = event.bytesTransferred / event.totalBytes;
          });
        });
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }
      if (widget.docId == null) {
        // New upload
        await FirebaseFirestore.instance.collection('gallery').add({
          'title': _titleController.text,
          'date': Timestamp.fromDate(_selectedDate!),
          'imageUrls': urls,
          'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Edit existing
        await FirebaseFirestore.instance.collection('gallery').doc(widget.docId).update({
          'title': _titleController.text,
          'date': Timestamp.fromDate(_selectedDate!),
          'imageUrls': urls,
        });
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery saved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving gallery: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Upload Gallery' : 'Edit Gallery'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              SizedBox(height: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text(_selectedDate == null
                    ? 'Select Day'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              Text('Existing Images:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (_existingImageUrls.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _existingImageUrls[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_existingImageUrls.isEmpty)
                Text('No existing images.'),
              SizedBox(height: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.photo_library),
                label: Text(_newImages.isEmpty
                    ? 'Add More Images'
                    : '${_newImages.length} new images selected'),
                onPressed: _pickImages,
              ),
              SizedBox(height: 12),
              if (_newImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: _newImages[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.orange[50],
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                      },
                                    )
                                  : Image.file(
                                      File(_newImages[index].path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            if (_uploadProgress[index] != null && _uploadProgress[index]! < 1.0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: SizedBox(
                                  width: 80,
                                  child: LinearProgressIndicator(
                                    value: _uploadProgress[index],
                                    backgroundColor: Colors.orange[100],
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenGalleryView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final void Function(String url) onDownload;
  const _FullScreenGalleryView({required this.imageUrls, required this.initialIndex, required this.onDownload});
  @override
  State<_FullScreenGalleryView> createState() => _FullScreenGalleryViewState();
}

class _FullScreenGalleryViewState extends State<_FullScreenGalleryView> {
  late PageController _controller;
  late int _currentIndex;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, idx) {
            return Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[idx],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 32,
          right: 16,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${_currentIndex + 1} / ${widget.imageUrls.length}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          right: 32,
          child: FloatingActionButton(
            backgroundColor: Colors.orange[700],
            child: Icon(Icons.download, color: Colors.white),
            onPressed: () {
              widget.onDownload(widget.imageUrls[_currentIndex]);
            },
          ),
        ),
      ],
    );
  }
} 