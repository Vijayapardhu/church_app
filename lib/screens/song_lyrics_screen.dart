import 'package:flutter/material.dart';

class SongLyricsScreen extends StatefulWidget {
  final String title;
  final String lyrics;
  final String? englishLyrics;

  const SongLyricsScreen({
    Key? key,
    required this.title,
    required this.lyrics,
    this.englishLyrics,
  }) : super(key: key);

  @override
  _SongLyricsScreenState createState() => _SongLyricsScreenState();
}

class _SongLyricsScreenState extends State<SongLyricsScreen> {
  double _fontSize = 18.0;
  final double _minFontSize = 12.0;
  final double _maxFontSize = 32.0;
  final double _fontSizeStep = 2.0;
  double _lastScale = 1.0;
  bool _isEnglish = false;

  void _increaseFontSize() {
    if (_fontSize < _maxFontSize) {
      setState(() {
        _fontSize += _fontSizeStep;
      });
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > _minFontSize) {
      setState(() {
        _fontSize -= _fontSizeStep;
      });
    }
  }

  void _toggleLanguage() {
    if (widget.englishLyrics != null) {
      setState(() {
        _isEnglish = !_isEnglish;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange[700]?.withOpacity(0.95),
        elevation: 0,
        actions: [
          if (widget.englishLyrics != null)
            IconButton(
              icon: Icon(_isEnglish ? Icons.translate : Icons.translate_outlined),
              onPressed: _toggleLanguage,
              tooltip: _isEnglish ? 'Switch to Telugu' : 'Switch to English',
            ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: _decreaseFontSize,
            tooltip: 'Decrease font size',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _increaseFontSize,
            tooltip: 'Increase font size',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[100]!, Colors.orange[50]!, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  shadowColor: Colors.orange[200],
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note, color: Colors.orange[700], size: 28),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(thickness: 1.2, color: Colors.orange[200]),
                        SizedBox(height: 16),
                        GestureDetector(
                          onScaleStart: (details) {
                            _lastScale = 1.0;
                          },
                          onScaleUpdate: (details) {
                            double scaleChange = details.scale - _lastScale;
                            if (scaleChange.abs() > 0.01) {
                              setState(() {
                                if (details.scale > _lastScale) {
                                  _fontSize = (_fontSize + _fontSizeStep).clamp(_minFontSize, _maxFontSize);
                                } else if (details.scale < _lastScale) {
                                  _fontSize = (_fontSize - _fontSizeStep).clamp(_minFontSize, _maxFontSize);
                                }
                              });
                              _lastScale = details.scale;
                            }
                          },
                          child: Text(
                            _isEnglish ? widget.englishLyrics! : widget.lyrics,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.7,
                              color: Colors.brown[900],
                              fontFamily: _isEnglish ? 'Arial' : 'Georgia',
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.englishLyrics != null)
              FloatingActionButton(
                heroTag: 'language',
                backgroundColor: Colors.orange[600],
                child: Icon(_isEnglish ? Icons.translate : Icons.translate_outlined, color: Colors.white),
                onPressed: _toggleLanguage,
                tooltip: _isEnglish ? 'Switch to Telugu' : 'Switch to English',
              ),
            SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'zoom_in',
              backgroundColor: Colors.orange[700],
              child: Icon(Icons.add, color: Colors.white),
              onPressed: _increaseFontSize,
              tooltip: 'Increase font size',
            ),
            SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'zoom_out',
              backgroundColor: Colors.orange[400],
              child: Icon(Icons.remove, color: Colors.white),
              onPressed: _decreaseFontSize,
              tooltip: 'Decrease font size',
            ),
          ],
        ),
      ),
    );
  }
} 