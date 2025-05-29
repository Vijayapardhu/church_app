import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firestore_service.dart';
import 'prayer_requests_screen.dart';
import 'prayer_approval_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';
import 'bible_screen.dart';
import 'songs_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;
  bool _isPastor = false;
  bool _isAdmin = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showBanner = true;
  bool _showUpdate = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  PageRouteBuilder fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _checkPastorRole();
    _initAudioPlayer();
  }

  Future<void> _checkUserRole() async {
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isPastor = userDoc.data()?['role'] == 'pastor';
          _isAdmin = userDoc.data()?['role'] == 'admin';
        });
      }
    }
  }

  Future<void> _checkPastorRole() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc['role'] == 'pastor') {
        setState(() {
          _isPastor = true;
        });
      }
    }
  }

  final List<Widget> _pages = [
    PrayerRequestsScreen(),
    GalleryScreen(),
    HomePage(),
    BibleScreen(),
    SongsScreen(),
  ];

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
        key: _scaffoldKey,
        appBar: _selectedIndex == 2
            ? AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.church, color: Colors.orange[700], size: 32),
                ),
                title: Text("Christ's Chapel Church Velangi"),
                backgroundColor: Colors.orange[700],
                elevation: 2,
                actions: [
                  if (_isAdmin)
                    IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _AudioRecordingDialog(),
                        );
                      },
                      tooltip: 'Record Audio Message',
                    ),
                  if (_isPastor)
                    IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _PastorMessageRecordDialog(),
                        );
                      },
                      tooltip: 'Record Daily Pastor Message',
                    ),
                  IconButton(
                    icon: Icon(Icons.person),
                    onPressed: () {
                      Navigator.push(
                        context,
                        fadeRoute(ProfileScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                    tooltip: 'Developer Info',
                  ),
                ],
              )
            : null,
        endDrawer: _DeveloperDrawer(),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange[50]!, Colors.orange[100]!],
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.orange[700],
            unselectedItemColor: Colors.brown[300],
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 0 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? Colors.orange[700]!.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.favorite_outline),
                ),
                label: 'Prayers',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? Colors.orange[700]!.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_outlined),
                ),
                label: 'Gallery',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? Colors.orange[700]!.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_rounded),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? Colors.orange[700]!.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_outlined),
                ),
                label: 'Bible',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 4 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 4
                        ? Colors.orange[700]!.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.music_note),
                ),
                label: 'Songs',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showBanner = true;
  bool _showUpdate = true;

  PageRouteBuilder fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio message')),
      );
    }
  }

  String _formatDuration(String? durationStr) {
    if (durationStr == null) return '';
    return durationStr;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Church Banner (if set)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('church_banner').doc('current').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !_showBanner) return SizedBox.shrink();
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              if (data == null || data['url'] == null) return SizedBox.shrink();
              return Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9, // Common aspect ratio for banners, adjust as needed
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(data['url']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () async {
                        // Only allow pastor to delete
                        final user = FirebaseAuth.instance.currentUser;
                        final doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
                        if (doc.exists && (doc['role'] == 'pastor' || doc['role'] == 'admin')) {
                          await FirebaseFirestore.instance.collection('church_banner').doc('current').delete();
                        } else {
                          setState(() => _showBanner = false);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Update Available Banner
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('app_updates').doc('latest').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !_showUpdate) return SizedBox.shrink();
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              if (data == null || data['url'] == null) return SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.system_update, color: Colors.orange[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A new update is available! Download the latest APK.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[800]),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final url = data['url'];
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch update URL'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Text('Download'),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.orange[700]),
                      onPressed: () => setState(() => _showUpdate = false),
                    ),
                  ],
                ),
              );
            },
          ),
          // Date and Time Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border(
                bottom: BorderSide(
                  color: Colors.orange[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  DateFormat('h:mm a').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.brown[500],
                  ),
                ),
              ],
            ),
          ),
          // Banner Section
          Container(
            height: 180,
            margin: EdgeInsets.symmetric(vertical: 25),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildBannerCard(
                  'Welcome to Christ\'s Chapel Church',
                  'Join us in worship',
                  Icons.church,
                ),
                _buildBannerCard(
                  'Sunday Service',
                  '10:00 AM - 12:30 PM',
                  Icons.access_time,
                  onTap: () {
                    final user = FirebaseAuth.instance.currentUser;
                    FirebaseFirestore.instance.collection('users').doc(user?.uid).get().then((doc) {
                      final isPastor = doc.exists && doc['role'] == 'pastor';
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SundayServiceNotesScreen(isPastor: isPastor),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    });
                  },
                ),
                _buildBannerCard(
                  'Bible Study',
                  'Wednesday 6:00 PM',
                  Icons.menu_book,
                ),
                _buildBannerCard(
                  'Youth Fellowship',
                  'Friday 6:00 PM',
                  Icons.people,
                ),
                _buildBannerCard(
                  'Prayer Meeting',
                  'Saturday 6:00 PM',
                  Icons.favorite,
                ),
              ],
            ),
          ),
          // Bible Verse of the Day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
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
                child: Stack(
                  children: [
                    // Decorative cross pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(Icons.menu_book, color: Colors.orange[700], size: 32),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: Colors.orange[700]),
                              SizedBox(width: 8),
                              Text(
                                'Bible Verse of the Day',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('daily_verse').doc('today').get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              final data = snapshot.data?.data() as Map<String, dynamic>?;
                              if (data != null && data['text'] != null && data['reference'] != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['text'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.brown[800],
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '- ${data['reference']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[700],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Fallback to automatic daily verse
                                return FutureBuilder<Map<String, dynamic>>(
                                  future: getDailyVerse(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                                    final verse = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          verse['text'] ?? '',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.brown[800],
                                            height: 1.5,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '- ${verse['book']} ${verse['chapter']}:${verse['verse']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown[700],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Pastor's Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
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
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(Icons.record_voice_over, color: Colors.orange[700], size: 32),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.record_voice_over, color: Colors.orange[700]),
                              SizedBox(width: 8),
                              Text(
                                'Pastor\'s Message',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('pastor_messages')
                                .doc('latest')
                                .snapshots(),
                            builder: (context, snapshot) {
                              print('Pastor Messages Debug:');
                              print('Has Data: ${snapshot.hasData}');
                              print('Has Error: ${snapshot.hasError}');
                              print('Error: ${snapshot.error}');
                              if (!snapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final message = snapshot.data!.data() as Map<String, dynamic>?;
                              print('Message data: $message');
                              if (message == null) {
                                print('No pastor message found');
                                return SizedBox.shrink();
                              }

                              if (message['audioUrl'] == null) {
                                print('No audio URL found in message');
                                return SizedBox.shrink();
                              }

                              print('Audio URL: ${message['audioUrl']}');

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                                color: Colors.orange[700],
                                                size: 48,
                                              ),
                                              onPressed: () {
                                                if (message['audioUrl'] != null) {
                                                  if (_isPlaying) {
                                                    _audioPlayer.pause();
                                                  } else {
                                                    _playAudio(message['audioUrl']);
                                                  }
                                                }
                                              },
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message['title'] ?? 'Weekly Message',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.brown[700],
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    message['description'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.brown[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              message['duration'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.brown[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 4,
                                            thumbShape: RoundSliderThumbShape(
                                              enabledThumbRadius: 6,
                                            ),
                                            overlayShape: RoundSliderOverlayShape(
                                              overlayRadius: 12,
                                            ),
                                          ),
                                          child: Slider(
                                            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1),
                                            min: 0,
                                            max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1,
                                            onChanged: (value) {
                                              final position = Duration(seconds: value.toInt());
                                              _audioPlayer.seek(position);
                                            },
                                            activeColor: Colors.orange[700],
                                            inactiveColor: Colors.orange[200],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Daily Inspiration Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StreamBuilder(
              stream: Provider.of<FirestoreService>(context).getDailyInspiration(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                if (data == null) return SizedBox.shrink();

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.record_voice_over, color: Colors.orange[700]),
                            SizedBox(width: 8),
                            Text(
                              'Daily Inspiration',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.brown[800],
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              if (data['verse'] != null) ...[
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '- ${data['verse']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.brown[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Bible Index: ${data['bibleIndex'] ?? 'John 3:16'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          // Today's Voice Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('daily_voice_messages')
                  .doc('latest')
                  .snapshots(),
              builder: (context, snapshot) {
                print('Daily Voice Messages Debug:');
                print('Has Data: ${snapshot.hasData}');
                print('Has Error: ${snapshot.hasError}');
                print('Error: ${snapshot.error}');
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final message = snapshot.data!.data() as Map<String, dynamic>?;
                print('Daily message data: $message');
                if (message == null) {
                  print('No daily voice message found');
                  return SizedBox.shrink();
                }

                final date = (message['date'] as Timestamp).toDate();
                print('Message date: $date');

                if (message['audioUrl'] == null) {
                  print('No audio URL found in daily message');
                  return SizedBox.shrink();
                }

                print('Daily message audio URL: ${message['audioUrl']}');

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.record_voice_over, color: Colors.orange[700]),
                            SizedBox(width: 8),
                            Text(
                              'Today\'s Message',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: Colors.orange[700],
                                      size: 48,
                                    ),
                                    onPressed: () {
                                      if (message['audioUrl'] != null) {
                                        if (_isPlaying) {
                                          _audioPlayer.pause();
                                        } else {
                                          _playAudio(message['audioUrl']);
                                        }
                                      }
                                    },
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['title'] ?? 'Daily Message',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(date),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.brown[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(message['duration']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.brown[500],
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: _position.inSeconds.toDouble(),
                                  min: 0,
                                  max: _duration.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    final position = Duration(seconds: value.toInt());
                                    _audioPlayer.seek(position);
                                  },
                                  activeColor: Colors.orange[700],
                                  inactiveColor: Colors.orange[200],
                                ),
                              ),
                            ],
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
    );
  }
}

Future<Map<String, dynamic>> getDailyVerse() async {
  final bookFiles = List.generate(66, (i) => 'assets/bible_books_json/${(i+1).toString().padLeft(2, '0')}.json');
  List<Map<String, dynamic>> allVerses = [];

  for (var file in bookFiles) {
    String data = await rootBundle.loadString(file);
    final jsonData = json.decode(data);
    final book = jsonData['books'][0];
    final chapters = book['chapters'] as List;
    for (var chapter in chapters) {
      final chapterNumber = chapter['number'];
      final verses = chapter['verses'] as List;
      for (var verse in verses) {
        allVerses.add({
          'book': book['name'] ?? file,
          'chapter': chapterNumber,
          'verse': verse['number'],
          'text': verse['text'],
        });
      }
    }
  }

  final now = DateTime.now();
  final dayOfYear = int.parse(DateFormat("D").format(now));
  final index = dayOfYear % allVerses.length;
  return allVerses[index];
}

class _AudioRecordingDialog extends StatefulWidget {
  @override
  _AudioRecordingDialogState createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<_AudioRecordingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _audioUrl;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  final _audioPlayer = AudioPlayer();
  final _audioRecorder = AudioRecorder();
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _recordingTimer?.cancel();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing recording: $e')),
      );
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _startRecordingTimer();
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resuming recording: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordedFilePath = path;
          _audioUrl = null;
          _recordingDuration = Duration.zero;
        });
        _startRecordingTimer();
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      try {
        await _audioPlayer.setFilePath(_recordedFilePath!);
        await _audioPlayer.play();
      } catch (e) {
        print('Error playing recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing recording: $e')),
        );
      }
    }
  }

  Future<void> _uploadRecording() async {
    if (_recordedFilePath == null) return;

    setState(() => _isLoading = true);

    try {
      final file = File(_recordedFilePath!);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('church_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _audioUrl = downloadUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('Error uploading recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading recording: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _audioUrl == null) return;
    
    setState(() { _isLoading = true; });
    
    try {
      await FirebaseFirestore.instance.collection('church_messages').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'audioUrl': _audioUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message uploaded successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading message: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Church Message'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter title' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Enter description' : null,
              ),
              SizedBox(height: 16),
              if (_isRecording || _isPaused)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isPaused ? Colors.orange[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPaused ? Icons.pause : Icons.mic, 
                           color: _isPaused ? Colors.orange[700] : Colors.red),
                      SizedBox(width: 8),
                      Text(
                        _isPaused 
                            ? 'Paused: ${_formatDuration(_recordingDuration)}'
                            : 'Recording: ${_formatDuration(_recordingDuration)}',
                        style: TextStyle(
                          color: _isPaused ? Colors.orange[700] : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.mic),
                    label: Text('Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                    onPressed: _isLoading || _isRecording || _isPaused ? null : _startRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.pause),
                    label: Text('Pause'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _isLoading || !_isRecording || _isPaused ? null : _pauseRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.stop),
                    label: Text('Stop'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _isLoading || (!_isRecording && !_isPaused) ? null : _stopRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text('Play'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _isLoading || _recordedFilePath == null ? null : _playRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: Text('Upload'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isLoading || _recordedFilePath == null || _audioUrl != null ? null : _uploadRecording,
                  ),
                ],
              ),
              if (_recordedFilePath != null && _audioUrl == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: Text('Upload Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _isLoading ? null : _uploadRecording,
                  ),
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
          onPressed: _isLoading || _audioUrl == null ? null : _submit,
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

class _PastorMessageRecordDialog extends StatefulWidget {
  @override
  State<_PastorMessageRecordDialog> createState() => _PastorMessageRecordDialogState();
}

class _PastorMessageRecordDialogState extends State<_PastorMessageRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _verseReferenceController = TextEditingController();
  final _verseTextController = TextEditingController();
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  String? _audioUrl;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _verseReferenceController.dispose();
    _verseTextController.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/pastor_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordedFilePath = path;
        _audioUrl = null;
        _recordingDuration = Duration.zero;
      });
      _startRecordingTimer();
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    _recordingTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    _startRecordingTimer();
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      await _audioPlayer.setFilePath(_recordedFilePath!);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (!state.playing) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  Future<void> _uploadRecording() async {
    if (_recordedFilePath == null) return;
    setState(() => _isLoading = true);
    try {
      final file = File(_recordedFilePath!);
      final ref = FirebaseStorage.instance
          .ref()
          .child('pastor_messages')
          .child('latest_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      setState(() {
        _audioUrl = downloadUrl;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording uploaded!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading recording: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _audioUrl == null) return;
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('pastor_messages').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'audioUrl': _audioUrl,
        'duration': _formatDuration(_recordingDuration),
        'verseReference': _verseReferenceController.text,
        'verseText': _verseTextController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message uploaded successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading message: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Pastor Message'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _verseReferenceController,
                decoration: InputDecoration(labelText: 'Daily Verse Reference (e.g., John 3:16)'),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _verseTextController,
                decoration: InputDecoration(labelText: 'Daily Verse Text'),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              if (_isRecording || _isPaused)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isPaused ? Colors.orange[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPaused ? Icons.pause : Icons.mic, 
                           color: _isPaused ? Colors.orange[700] : Colors.red),
                      SizedBox(width: 8),
                      Text(
                        _isPaused 
                            ? 'Paused: ${_formatDuration(_recordingDuration)}'
                            : 'Recording: ${_formatDuration(_recordingDuration)}',
                        style: TextStyle(
                          color: _isPaused ? Colors.orange[700] : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_recordedFilePath != null && !_isRecording && !_isPaused)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Pause' : 'Play'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _isPlaying ? null : _playRecording,
                    ),
                  ],
                ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.mic),
                    label: Text('Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                    onPressed: _isLoading || _isRecording || _isPaused ? null : _startRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.pause),
                    label: Text('Pause'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _isLoading || !_isRecording || _isPaused ? null : _pauseRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.stop),
                    label: Text('Stop'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _isLoading || (!_isRecording && !_isPaused) ? null : _stopRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text('Play'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _isLoading || _recordedFilePath == null ? null : _playRecording,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: Text('Upload'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isLoading || _recordedFilePath == null || _audioUrl != null ? null : _uploadRecording,
                  ),
                ],
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
          onPressed: _isLoading || _audioUrl == null ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
          child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text('Upload'),
        ),
      ],
    );
  }
}

class _PastorUploadDialog extends StatefulWidget {
  @override
  State<_PastorUploadDialog> createState() => _PastorUploadDialogState();
}

class _PastorUploadDialogState extends State<_PastorUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _verseTextController = TextEditingController();
  final _verseReferenceController = TextEditingController();
  bool _isLoading = false;
  bool _isVerse = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _verseTextController.dispose();
    _verseReferenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isVerse) {
        // Save Bible verse
        await FirebaseFirestore.instance.collection('daily_verse').doc('today').set({
          'text': _verseTextController.text,
          'reference': _verseReferenceController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Save daily message
        await FirebaseFirestore.instance.collection('pastor_messages').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isVerse ? 'Verse saved!' : 'Message saved!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isVerse ? 'Add Bible Verse' : 'Add Daily Message'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Message'),
                      value: false,
                      groupValue: _isVerse,
                      onChanged: (v) => setState(() => _isVerse = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Verse'),
                      value: true,
                      groupValue: _isVerse,
                      onChanged: (v) => setState(() => _isVerse = v!),
                    ),
                  ),
                ],
              ),
              if (!_isVerse) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                ),
              ],
              if (_isVerse) ...[
                TextFormField(
                  controller: _verseReferenceController,
                  decoration: InputDecoration(labelText: 'Verse Reference (e.g., John 3:16)'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter reference' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _verseTextController,
                  decoration: InputDecoration(labelText: 'Verse Text'),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Enter verse text' : null,
                ),
              ],
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
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
          child: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Save'),
        ),
      ],
    );
  }
}

Widget _buildBannerCard(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
  return Container(
    width: 280,
    margin: EdgeInsets.only(right: 16),
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
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Colors.orange[700],
                  ),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.brown[500],
                    ),
                  ),
                ],
              ),
            ),
            if (title == 'Sunday Service')
              Positioned(
                top: 8,
                right: 8,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                    final isPastor = snapshot.data?.get('role') == 'pastor';
                    if (!isPastor) return SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => SundayServiceNotesScreen(isPastor: true),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      tooltip: 'Edit Sunday Service Notes',
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

class SundayServiceNotesScreen extends StatefulWidget {
  final bool isPastor;
  const SundayServiceNotesScreen({Key? key, required this.isPastor}) : super(key: key);

  @override
  State<SundayServiceNotesScreen> createState() => _SundayServiceNotesScreenState();
}

class _SundayServiceNotesScreenState extends State<SundayServiceNotesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() { _isLoading = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('sunday_service_notes').doc('current').get();
      if (doc.exists && doc['notes'] != null) {
        _controller.text = doc['notes'];
      }
    } catch (e) {
      setState(() { _error = 'Failed to load notes.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveNotes() async {
    setState(() { _isSaving = true; });
    try {
      await FirebaseFirestore.instance.collection('sunday_service_notes').doc('current').set({
        'notes': _controller.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() { _isEditing = false; });
      _animationController.reverse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Notes saved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(8),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to save notes'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(8),
        ),
      );
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _loadNotes(); // Reload original notes when canceling edit
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sunday Service Notes'),
        backgroundColor: Colors.orange[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[50]!, Colors.white],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Colors.orange[700], size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Sunday Service Notes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: _controller,
                              enabled: widget.isPastor && _isEditing,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Enter Sunday service notes... (visible to all users)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.all(16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.brown[900],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.isPastor)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedOpacity(
                                  opacity: _isEditing ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 300),
                                  child: ElevatedButton.icon(
                                    icon: _isSaving
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Icon(Icons.save),
                                    label: Text('Save Notes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: _isSaving || !_isEditing ? null : _saveNotes,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: Icon(_isEditing ? Icons.edit_off : Icons.edit),
                                label: Text(_isEditing ? 'Cancel Edit' : 'Edit Notes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEditing ? Colors.red[400] : Colors.blue[400],
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _toggleEditMode,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DeveloperDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _AnimatedDrawerHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Removed Personal Info section
                  // Divider(height: 24),
                  Text('Developer Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[700])),
                  SizedBox(height: 8),
                  _infoRow(Icons.build, 'Tools', 'Sketchware, Android Studio, Firebase'),
                  _infoRow(Icons.apps, 'Apps Developed', 'College, Church, E-commerce, Productivity, Token Generator'),
                  Divider(height: 24),
                  Text('Vision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[700])),
                  SizedBox(height: 8),
                  Text(
                    '"I build apps that are simple, helpful, and meaningful — focused on education, community, and spiritual growth. My goal is to use technology to connect people, support students, and make everyday tasks easier through creative development."',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown[700]),
                  ),
                  Divider(height: 24),
                  // Contact and social links
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.orange[700], size: 18),
                      SizedBox(width: 6),
                      Text('vijayapardhu17@gmail.com', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange[700], size: 18),
                      SizedBox(width: 6),
                      Text('Velangi, Kakinada, Andhra Pradesh', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.orange[700], size: 18),
                      SizedBox(width: 6),
                      Text('9494429963', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Social links row (replace previous Row with GestureDetectors)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.code, color: Colors.black, size: 28),
                        onPressed: () => _launchUrl('https://github.com/Vijayapardhu'),
                        tooltip: 'GitHub',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.business, color: Colors.blue, size: 28),
                        onPressed: () => _launchUrl('https://www.linkedin.com/in/vijayapardhu179'),
                        tooltip: 'LinkedIn',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.purple, size: 28),
                        onPressed: () => _launchUrl('https://instagram.com/vijayaaapardhu'),
                        tooltip: 'Instagram',
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange[700], size: 18),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[800])),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.brown[700])),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}

class _AnimatedDrawerHeader extends StatefulWidget {
  @override
  State<_AnimatedDrawerHeader> createState() => _AnimatedDrawerHeaderState();
}

class _AnimatedDrawerHeaderState extends State<_AnimatedDrawerHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: Colors.orange[700],
      end: Colors.deepOrange[400],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return DrawerHeader(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Removed animated avatar
              // AnimatedContainer(
              //   duration: Duration(milliseconds: 600),
              //   curve: Curves.easeInOut,
              //   width: 64,
              //   height: 64,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     gradient: LinearGradient(
              //       colors: [Colors.orange[700]!, Colors.deepOrange[400]!],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.08),
              //         blurRadius: 8,
              //         offset: Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child: Center(
              //     child: Text(
              //       'MVP',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 28,
              //         letterSpacing: 2,
              //       ),
              //     ),
              //   ),
              // ),
              SizedBox(height: 12),
              Text(
                'M. Vijaya pardhu (MVP)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Age: 17',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Diploma in CME, Aditya Polytechnic College',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 10),
              // Animated Social Icons Row
              _AnimatedSocialIcons(),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedSocialIcons extends StatefulWidget {
  @override
  State<_AnimatedSocialIcons> createState() => _AnimatedSocialIconsState();
}

class _AnimatedSocialIconsState extends State<_AnimatedSocialIcons> with TickerProviderStateMixin {
  late final AnimationController _githubController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
  late final AnimationController _linkedinController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
  late final AnimationController _instaController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);

  @override
  void dispose() {
    _githubController.dispose();
    _linkedinController.dispose();
    _instaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAnimatedIcon(
          controller: _githubController,
          icon: Icons.code,
          color: Colors.black,
          url: 'https://github.com/Vijayapardhu',
        ),
        SizedBox(width: 16),
        _buildAnimatedIcon(
          controller: _linkedinController,
          icon: Icons.business,
          color: Colors.blue[700]!,
          url: 'https://www.linkedin.com/in/vijayapardhu179',
        ),
        SizedBox(width: 16),
        _buildAnimatedIcon(
          controller: _instaController,
          icon: Icons.camera_alt,
          color: Colors.purple,
          url: 'https://instagram.com/vijayaapardhu',
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon({
    required AnimationController controller,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) async {
        controller.reverse();
        if (await canLaunch(url)) await launch(url);
      },
      onTapCancel: () => controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => Icon(
            icon,
            color: color.withOpacity(0.7 + 0.3 * controller.value),
            size: 32,
          ),
        ),
      ),
    );
  }
} 