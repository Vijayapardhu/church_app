import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:church_app/screens/song_lyrics_screen.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SongsScreen extends StatefulWidget {
  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final List<String> teluguLetters = [
    'అ', 'ఆ', 'ఇ', 'ఈ', 'ఉ', 'ఊ', 'ఎ', 'ఏ', 'ఐ', 'ఒ', 'ఓ',
    'ఔ', 'క', 'ఖ', 'గ', 'ఘ', 'చ', 'ఛ', 'జ', 'ఝ', 'ట', 'ఠ',
    'డ', 'ఢ', 'త', 'థ', 'ద', 'ధ', 'న', 'ప', 'ఫ', 'బ', 'భ',
    'మ', 'య', 'ర', 'ల', 'వ', 'శ', 'ష', 'స', 'హ', 'ళ', 'క్ష', 'ఱ', '#'
  ];
  String? selectedLetter;
  String searchQuery = '';
  bool _isPastor = false;

  @override
  void initState() {
    super.initState();
    _checkPastorRole();
  }

  Future<void> _checkPastorRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc['role'] == 'pastor') {
        setState(() {
          _isPastor = true;
        });
      }
    }
  }

  void _openUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _UploadSongDialog(teluguLetters: teluguLetters),
    );
  }

  void _openBulkUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _BulkUploadDialog(teluguLetters: teluguLetters),
    );
  }

  void _openLyricsScreen(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SongLyricsScreen(
          title: data['titleTelugu'] ?? data['titleEnglish'] ?? 'No Title',
          lyrics: data['lyrics'] ?? 'No lyrics available',
          englishLyrics: data['englishLyrics'],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
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
          title: Text('Songs'),
          backgroundColor: Colors.orange[700],
          actions: [
            if (_isPastor) ...[
              IconButton(
                icon: Icon(Icons.upload_file),
                tooltip: 'Upload Single Song',
                onPressed: _openUploadDialog,
              ),
              IconButton(
                icon: Icon(Icons.upload),
                tooltip: 'Bulk Upload Songs',
                onPressed: _openBulkUploadDialog,
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Telugu letter grid
            Container(
              color: Colors.orange[50],
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    'Select Letter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: teluguLetters.map((letter) {
                      final isSelected = selectedLetter == letter;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedLetter = letter;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [Colors.orange[700]!, Colors.orange[400]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.white, Colors.orange[100]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.orange[700]! : Colors.orange[200]!,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.brown[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Telugu or English title...',
                    prefixIcon: Icon(Icons.search, color: Colors.orange[700]),
                    filled: true,
                    fillColor: Colors.orange[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            // Song list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('songs')
                    .orderBy('startingLetter')
                    .orderBy('titleTelugu')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final songs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final titleTelugu = data['titleTelugu']?.toString() ?? '';
                    final titleEnglish = data['titleEnglish']?.toString() ?? '';
                    final letter = data['startingLetter']?.toString() ?? '';
                    final matchesLetter = selectedLetter == null || selectedLetter == '#' || letter == selectedLetter;
                    final matchesSearch = searchQuery.isEmpty ||
                      titleTelugu.contains(searchQuery) ||
                      titleEnglish.toLowerCase().contains(searchQuery.toLowerCase());
                    return matchesLetter && matchesSearch;
                  }).toList();
                  if (songs.isEmpty) {
                    return Center(child: Text('No songs found.'));
                  }

                  // Group songs by starting letter
                  Map<String, List<QueryDocumentSnapshot>> groupedSongs = {};
                  for (var song in songs) {
                    final data = song.data() as Map<String, dynamic>;
                    final letter = data['startingLetter']?.toString() ?? '#';
                    if (!groupedSongs.containsKey(letter)) {
                      groupedSongs[letter] = [];
                    }
                    groupedSongs[letter]!.add(song);
                  }

                  // Sort letters according to teluguLetters order
                  List<String> sortedLetters = groupedSongs.keys.toList()
                    ..sort((a, b) => teluguLetters.indexOf(a).compareTo(teluguLetters.indexOf(b)));

                  return ListView.builder(
                    itemCount: sortedLetters.length,
                    itemBuilder: (context, index) {
                      final letter = sortedLetters[index];
                      final letterSongs = groupedSongs[letter]!;
                      return Column(
                        children: [
                          Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                                splashColor: Colors.orange[50],
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.orange[700],
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${letter} - ${letterSongs.length} Songs',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[800],
                                  ),
                                ),
                                children: letterSongs.map((song) {
                                  final data = song.data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _openLyricsScreen(context, data),
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [Colors.orange[50]!, Colors.orange[100]!],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 6,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.orange[400],
                                                child: Icon(Icons.music_note, color: Colors.white),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      data['titleTelugu'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.brown[800],
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      data['titleEnglish'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.brown[600],
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.music_note, size: 16, color: Colors.orange[700]),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Tap to view lyrics',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.orange[700],
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.orange[700],
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          if (index < sortedLetters.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Divider(color: Colors.orange[200], thickness: 1.2),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadSongDialog extends StatefulWidget {
  final List<String> teluguLetters;
  const _UploadSongDialog({required this.teluguLetters});
  @override
  State<_UploadSongDialog> createState() => _UploadSongDialogState();
}

class _UploadSongDialogState extends State<_UploadSongDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleTeluguController = TextEditingController();
  final _titleEnglishController = TextEditingController();
  final _lyricsController = TextEditingController();
  String? _selectedLetter;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleTeluguController.dispose();
    _titleEnglishController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate() || _selectedLetter == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('songs').add({
        'titleTelugu': _titleTeluguController.text,
        'titleEnglish': _titleEnglishController.text,
        'lyrics': _lyricsController.text,
        'startingLetter': _selectedLetter,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Song uploaded successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading song'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload Song Lyrics'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleTeluguController,
                decoration: InputDecoration(labelText: 'Song Title (Telugu)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter Telugu title' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _titleEnglishController,
                decoration: InputDecoration(labelText: 'Song Title (English)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter English title' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _lyricsController,
                decoration: InputDecoration(labelText: 'Lyrics'),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Enter lyrics' : null,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.teluguLetters.map((letter) {
                  final isSelected = _selectedLetter == letter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLetter = letter;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange[700] : Colors.grey[900],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.cyan[100],
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _uploadSong,
          child: _isLoading ? CircularProgressIndicator() : Text('Upload'),
        ),
      ],
    );
  }
}

class _BulkUploadDialog extends StatefulWidget {
  final List<String> teluguLetters;
  const _BulkUploadDialog({required this.teluguLetters});
  @override
  State<_BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<_BulkUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jsonController = TextEditingController();
  bool _isLoading = false;
  List<String> _selectedFileNames = [];
  List<String> _jsonContents = [];

  Future<void> _pickJsonFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFileNames = result.files.map((file) => file.name).toList();
          _jsonContents = [];
        });

        // Process each file
        for (var file in result.files) {
          if (file.path != null) {
            final jsonString = await File(file.path!).readAsString();
            _jsonContents.add(jsonString);
          }
        }

        // Combine all JSON contents
        _jsonController.text = _jsonContents.join('\n');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadSongs() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final songsCollection = FirebaseFirestore.instance.collection('songs');
      int totalSongs = 0;

      // Process each JSON content
      for (var jsonString in _jsonContents) {
        final jsonData = json.decode(jsonString);
        if (jsonData is! List) {
          throw Exception('JSON must be an array of songs');
        }

        for (var song in jsonData) {
          if (song is! Map<String, dynamic>) {
            throw Exception('Each song must be an object');
          }

          // Validate required fields
          if (!song.containsKey('titleTelugu') || 
              !song.containsKey('titleEnglish') || 
              !song.containsKey('lyrics') ||
              !song.containsKey('startingLetter')) {
            throw Exception('Each song must have titleTelugu, titleEnglish, lyrics, and startingLetter');
          }

          // Validate starting letter
          if (!widget.teluguLetters.contains(song['startingLetter'])) {
            throw Exception('Invalid starting letter: ${song['startingLetter']}');
          }

          final docRef = songsCollection.doc();
          batch.set(docRef, {
            ...song,
            'createdAt': FieldValue.serverTimestamp(),
          });
          totalSongs++;
        }
      }

      await batch.commit();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$totalSongs songs uploaded successfully from ${_selectedFileNames.length} files'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading songs: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bulk Upload Songs'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload songs via JSON files or paste JSON:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickJsonFiles,
                icon: Icon(Icons.upload_file),
                label: Text('Choose JSON Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                ),
              ),
              if (_selectedFileNames.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Selected files:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                ..._selectedFileNames.map((fileName) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, size: 16, color: Colors.green[700]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(color: Colors.green[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
              SizedBox(height: 16),
              Text(
                'Example format:\n'
                '[\n'
                '  {\n'
                '    "titleTelugu": "స్తోత్రం",\n'
                '    "titleEnglish": "Praise",\n'
                '    "lyrics": "Song lyrics here...",\n'
                '    "englishLyrics": "English lyrics here...",\n'
                '    "startingLetter": "స"\n'
                '  }\n'
                ']',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _jsonController,
                decoration: InputDecoration(
                  hintText: 'Paste JSON here or upload files...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter JSON data or upload files';
                  }
                  try {
                    json.decode(value);
                  } catch (e) {
                    return 'Invalid JSON format';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _uploadSongs,
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
              : Text('Upload'),
        ),
      ],
    );
  }
} 