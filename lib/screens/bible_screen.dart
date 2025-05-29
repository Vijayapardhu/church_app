import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
//import 'package:cloud_firestore/cloud_firestore.dart';

final List<String> teluguBookNames = [
  'ఆదికాండము', 'నిర్గమకాండము', 'లేవీయకాండము', 'సంఖ్యాకాండము', 'ద్వితీయోపదేశకాండము',
  'యెహోషువ', 'న్యాయాధిపతులు', 'రూతు', 'సమూయేలు మొదటి గ్రంథము', 'సమూయేలు రెండవ గ్రంథము',
  'రాజులు మొదటి గ్రంథము', 'రాజులు రెండవ గ్రంథము', 'దినవృత్తాంతములు మొదటి గ్రంథము', 'దినవృత్తాంతములు రెండవ గ్రంథము',
  'ఎజ్రా', 'నెహెమ్యా', 'ఎస్తేరు', 'యోబు', 'కీర్తనలు', 'సామెతలు', 'ప్రసంగి', 'పరమగీతము',
  'యెషయా', 'యిర్మియా', 'విలాపవాక్యములు', 'యెహెజ్కేలు', 'దానియేలు', 'హోషేయ', 'యోవేలు',
  'ఆమోసు', 'ఓబద్యా', 'యోనా', 'మీకా', 'నాహూము', 'హబక్కూకు', 'జెఫన్యా', 'హగ్గయి', 'జెకర్యా', 'మలాకీ',
  'మత్తయి సువార్త', 'మార్కు సువార్త', 'లూకా సువార్త', 'యోహాను సువార్త', 'అపొస్తలుల కార్యములు',
  'రోమీయులకు', '1 కొరింథీయులకు', '2 కొరింథీయులకు', 'గలతీయులకు', 'ఎఫెసీయులకు', 'ఫిలిప్పీయులకు',
  'కొలస్సయులకు', '1 థెస్సలొనీకయులకు', '2 థెస్సలొనీకయులకు', '1 తిమోతికి', '2 తిమోతికి', 'తీతుకు',
  'ఫిలేమోనుకు', 'హెబ్రీయులకు', 'యాకోబు', '1 పేతురు', '2 పేతురు', '1 యోహాను', '2 యోహాను',
  '3 యోహాను', 'యూదా', 'ప్రకటన గ్రంథము',
];

const Color kLightOrange = Color(0xFFFFE0B2); // Light orange background
const Color kOrange = Color(0xFFFF9800);      // Main orange
const Color kOrangeDark = Color(0xFFF57C00);  // Darker orange for accents

class BibleScreen extends StatefulWidget {
  const BibleScreen({Key? key}) : super(key: key);
  @override
  _BibleScreenState createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  int? selectedBookIndex;
  Map<String, dynamic>? bookData;
  int? selectedChapterIndex;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 18.0;
  final double _minFontSize = 12.0;
  final double _maxFontSize = 32.0;
  double _lastScale = 1.0;
  int? highlightedVerse;
  String? _selectedBook;
  int? _selectedChapter;
  String? _selectedVerse;
  PageController? _chapterPageController;

  final List<String> _oldTestament = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
    'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
    'Zephaniah', 'Haggai', 'Zechariah', 'Malachi'
  ];

  final List<String> _newTestament = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy',
    '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
    '1 Peter', '2 Peter', '1 John', '2 John', '3 John',
    'Jude', 'Revelation'
  ];

  Map<String, int> _chapterCounts = {
    'Genesis': 50, 'Exodus': 40, 'Leviticus': 27, 'Numbers': 36, 'Deuteronomy': 34,
    'Joshua': 24, 'Judges': 21, 'Ruth': 4, '1 Samuel': 31, '2 Samuel': 24,
    '1 Kings': 22, '2 Kings': 25, '1 Chronicles': 29, '2 Chronicles': 36, 'Ezra': 10,
    'Nehemiah': 13, 'Esther': 10, 'Job': 42, 'Psalms': 150, 'Proverbs': 31,
    'Ecclesiastes': 12, 'Song of Solomon': 8, 'Isaiah': 66, 'Jeremiah': 52, 'Lamentations': 5,
    'Ezekiel': 48, 'Daniel': 12, 'Hosea': 14, 'Joel': 3, 'Amos': 9,
    'Obadiah': 1, 'Jonah': 4, 'Micah': 7, 'Nahum': 3, 'Habakkuk': 3,
    'Zephaniah': 3, 'Haggai': 2, 'Zechariah': 14, 'Malachi': 4,
    'Matthew': 28, 'Mark': 16, 'Luke': 24, 'John': 21, 'Acts': 28,
    'Romans': 16, '1 Corinthians': 16, '2 Corinthians': 13, 'Galatians': 6, 'Ephesians': 6,
    'Philippians': 4, 'Colossians': 4, '1 Thessalonians': 5, '2 Thessalonians': 3, '1 Timothy': 6,
    '2 Timothy': 4, 'Titus': 3, 'Philemon': 1, 'Hebrews': 13, 'James': 5,
    '1 Peter': 5, '2 Peter': 3, '1 John': 5, '2 John': 1, '3 John': 1,
    'Jude': 1, 'Revelation': 22
  };

  @override
  void dispose() {
    _scrollController.dispose();
    _chapterPageController?.dispose();
    super.dispose();
  }

  Future<void> _loadBookJson(int bookIndex) async {
    setState(() { isLoading = true; });
    final fileNum = (bookIndex + 1).toString().padLeft(2, '2');
    final jsonString = await rootBundle.loadString('assets/bible_books_json/$fileNum.json');
    setState(() {
      bookData = jsonDecode(jsonString);
      selectedBookIndex = bookIndex;
      selectedChapterIndex = null;
      isLoading = false;
      _chapterPageController = PageController();
    });
  }

  void _copyVerse(String verseText, dynamic verseNumber) {
    final bookName = teluguBookNames[selectedBookIndex!];
    final chapter = selectedChapterIndex! + 1;
    final reference = '$bookName $chapter:${verseNumber.toString()}';
    final textToCopy = '$verseText\n\n$reference';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $reference'),
        backgroundColor: kOrangeDark,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _selectBook(String book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _selectedVerse = null;
    });
  }

  void _selectChapter(int chapter) {
    setState(() {
      _selectedChapter = chapter;
      _selectedVerse = null;
    });
  }

  Widget _buildBookGrid() {
    return Container(
      color: kLightOrange,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Old Testament Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'పాత నిబంధన',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kOrangeDark,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: 39, // Old Testament books
                          itemBuilder: (context, index) {
                            return Card(
                              color: Colors.white,
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _loadBookJson(index),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    teluguBookNames[index],
                                    style: TextStyle(
                                      color: kOrangeDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
                // Divider
                Container(
                  width: 1,
                  color: kOrange.withAlpha((255 * 0.3).toInt()),
                ),
                // New Testament Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'క్రొత్త నిబంధన',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kOrangeDark,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: 27, // New Testament books
                          itemBuilder: (context, index) {
                            final bookIndex = index + 39; // Start from index 39
                            return Card(
                              color: Colors.white,
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _loadBookJson(bookIndex),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    teluguBookNames[bookIndex],
                                    style: TextStyle(
                                      color: kOrangeDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (selectedBookIndex != null && selectedChapterIndex != null) {
            setState(() {
              selectedChapterIndex = null;
              highlightedVerse = null;
            });
            return;
          }
          if (selectedBookIndex != null && selectedChapterIndex == null) {
            setState(() {
              selectedBookIndex = null;
              bookData = null;
            });
            return;
          }
          // If on book selection, show exit dialog
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
          if (shouldExit == true) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            selectedBookIndex == null
                ? 'Holy Bible'
                : selectedChapterIndex == null
                    ? teluguBookNames[selectedBookIndex!]
                    : '${teluguBookNames[selectedBookIndex!]} - అధ్యాయం ${selectedChapterIndex! + 1}',
          ),
           backgroundColor: Colors.orange[700],
          elevation: 0,
          leading: (selectedBookIndex != null || selectedChapterIndex != null)
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    if (selectedChapterIndex != null) {
                      setState(() {
                        selectedChapterIndex = null;
                        highlightedVerse = null;
                      });
                    } else {
                      setState(() {
                        selectedBookIndex = null;
                        bookData = null;
                      });
                    }
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (_fontSize > _minFontSize) _fontSize -= 2.0;
                });
              },
              tooltip: 'Decrease font size',
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  if (_fontSize < _maxFontSize) _fontSize += 2.0;
                });
              },
              tooltip: 'Increase font size',
            ),
            IconButton(
              icon: Icon(Icons.search),
              tooltip: 'Jump to verse',
              onPressed: () async {
                final result = await showDialog<Map<String, int>>(
                  context: context,
                  builder: (context) => _JumpDialog(),
                );
                if (result != null) {
                  final bookIdx = result['book']!;
                  final chapterIdx = result['chapter']!;
                  final verseIdx = result['verse']!;
                  if (selectedBookIndex != bookIdx) {
                    await _loadBookJson(bookIdx);
                  }
                  setState(() {
                    selectedChapterIndex = chapterIdx;
                  });
                  await Future.delayed(Duration(milliseconds: 100));
                  _chapterPageController?.jumpToPage(chapterIdx);
                  setState(() {
                    highlightedVerse = verseIdx;
                  });
                  await Future.delayed(Duration(milliseconds: 200));
                  _scrollToVerse(verseIdx);
                }
              },
            ),
          ],
        ),
        backgroundColor: kLightOrange,
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: kOrangeDark),
              )
            : selectedBookIndex == null
                ? _buildBookGrid()
                : selectedChapterIndex == null
                    ? Container(
                        color: kLightOrange,
                        child: GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: (bookData!['chapters'] as List).length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => setState(() => selectedChapterIndex = index),
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    'అధ్యాయం ${index + 1}',
                                    style: TextStyle(
                                      color: kOrangeDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: kLightOrange,
                        child: GestureDetector(
                          onScaleStart: (details) {
                            _lastScale = 1.0;
                          },
                          onScaleUpdate: (details) {
                            double scaleChange = details.scale - _lastScale;
                            if (scaleChange.abs() > 0.01) {
                              setState(() {
                                _fontSize = (_fontSize * details.scale).clamp(_minFontSize, _maxFontSize);
                              });
                              _lastScale = details.scale;
                            }
                          },
                        child: PageView.builder(
                            controller: _chapterPageController,
                          itemCount: (bookData!['chapters'] as List).length,
                          onPageChanged: (page) {
                            setState(() {
                              selectedChapterIndex = page;
                              highlightedVerse = null;
                            });
                          },
                          itemBuilder: (context, chapterPageIndex) {
                            final chapter = bookData!['chapters'][chapterPageIndex];
                            return ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16),
                              itemCount: (chapter['verses'] as List).length,
                              itemBuilder: (context, index) {
                                final verse = chapter['verses'][index];
                                final isHighlighted = highlightedVerse == index && selectedChapterIndex == chapterPageIndex;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: isHighlighted ? kOrange.withAlpha((255 * 0.2).toInt()) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kOrange.withAlpha((255 * 0.08).toInt()),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      highlightedVerse = isHighlighted ? null : index;
                                    }),
                                    onLongPress: () => _copyVerse(verse['text'], verse['number']),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            margin: EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              color: isHighlighted ? kOrange : kOrange.withAlpha((255 * 0.2).toInt()),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${verse['number']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              verse['text'],
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                height: 1.5,
                                                color: kOrangeDark,
                                                fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.copy, size: 20, color: kOrangeDark),
                                            onPressed: () => _copyVerse(verse['text'], verse['number']),
                                            tooltip: 'Copy verse',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
      ),
      ),
    );
  }

  void _scrollToVerse(int verseIdx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final position = verseIdx * 60.0; // Approximate item height
      _scrollController.animateTo(
        position,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }
}

class _JumpDialog extends StatefulWidget {
  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  int _selectedBook = 0;
  final TextEditingController _chapterController = TextEditingController(text: '1');
  final TextEditingController _verseController = TextEditingController(text: '1');
  int _maxChapter = 1;
  int _maxVerse = 1;
  List chapters = [];
  List verses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  void _loadChapters() async {
    final fileNum = (_selectedBook + 1).toString().padLeft(2, '2');
    final jsonString = await rootBundle.loadString('assets/bible_books_json/$fileNum.json');
    final bookData = jsonDecode(jsonString);
    setState(() {
      chapters = bookData['chapters'];
      _maxChapter = chapters.length;
      _chapterController.text = '1';
      verses = chapters.isNotEmpty ? chapters[0]['verses'] : [];
      _maxVerse = verses.length;
      _verseController.text = '1';
    });
  }

  void _updateMaxVerse() {
    int chapterIdx = int.tryParse(_chapterController.text) ?? 1;
    if (chapterIdx < 1) chapterIdx = 1;
    if (chapterIdx > _maxChapter) chapterIdx = _maxChapter;
    if (chapters.isNotEmpty && chapterIdx - 1 < chapters.length) {
      verses = chapters[chapterIdx - 1]['verses'];
      _maxVerse = verses.length;
      if ((int.tryParse(_verseController.text) ?? 1) > _maxVerse) {
        _verseController.text = '1';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Jump to Verse'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _selectedBook,
            isExpanded: true,
            items: List.generate(teluguBookNames.length, (i) => DropdownMenuItem(
              value: i,
              child: Text(teluguBookNames[i]),
            )),
            onChanged: (val) {
              setState(() {
                _selectedBook = val!;
              });
              _loadChapters();
            },
          ),
          SizedBox(height: 12),
          TextField(
            controller: _chapterController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chapter (1 - $_maxChapter)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _updateMaxVerse();
              });
            },
          ),
          SizedBox(height: 12),
          TextField(
            controller: _verseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Verse (1 - $_maxVerse)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            int chapter = int.tryParse(_chapterController.text) ?? 1;
            int verse = int.tryParse(_verseController.text) ?? 1;
            if (chapter < 1 || chapter > _maxChapter) {
              setState(() { _error = 'Invalid chapter number.'; });
              return;
            }
            if (verse < 1 || verse > _maxVerse) {
              setState(() { _error = 'Invalid verse number.'; });
              return;
            }
            Navigator.pop(context, {
              'book': _selectedBook,
              'chapter': chapter - 1,
              'verse': verse - 1,
            });
          },
          child: Text('Jump'),
        ),
      ],
    );
  }
} 