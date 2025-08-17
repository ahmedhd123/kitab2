import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';

class SimpleBookReaderScreen extends StatefulWidget {
  final BookModel book;

  const SimpleBookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<SimpleBookReaderScreen> createState() => _SimpleBookReaderScreenState();
}

class _SimpleBookReaderScreenState extends State<SimpleBookReaderScreen> {
  int _currentPage = 1;
  bool _showControls = true;
  final PageController _pageController = PageController();
  late DateTime _readingStartTime;
  Map<String, dynamic> _bookmarks = {};
  Map<String, dynamic> _highlights = {}; // page -> List<String>

  @override
  void initState() {
    super.initState();
    _readingStartTime = DateTime.now();
    _loadSavedProgress();
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  void _loadSavedProgress() {
  final authService = Provider.of<AuthFirebaseService>(context, listen: false);
    final bookService = Provider.of<BookService>(context, listen: false);
    
    final uid = authService.currentUser?.uid;
    // prefer remote sync when user is signed in
    if (uid != null && uid.isNotEmpty) {
      bookService.syncReadingProgressFromRemote(widget.book.id, uid).then((progress) {
        if (progress != null && mounted) {
          setState(() {
            _currentPage = progress.currentPage;
            _bookmarks = Map<String, dynamic>.from(progress.bookmarks);
            _highlights = Map<String, dynamic>.from(progress.highlights);
          });
          _pageController.animateToPage(
            _currentPage - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }).catchError((_) {
        // fallback to local progress
        final progress = bookService.getReadingProgress(
          widget.book.id,
          uid,
        );
        if (progress != null && mounted) {
          setState(() {
            _currentPage = progress.currentPage;
            _bookmarks = Map<String, dynamic>.from(progress.bookmarks);
            _highlights = Map<String, dynamic>.from(progress.highlights);
          });
          _pageController.animateToPage(
            _currentPage - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    // fallback: use local progress if no signed-in user
    final progress = bookService.getReadingProgress(
      widget.book.id,
      uid ?? '',
    );

    if (progress != null) {
      setState(() {
        _currentPage = progress.currentPage;
        _bookmarks = Map<String, dynamic>.from(progress.bookmarks);
        _highlights = Map<String, dynamic>.from(progress.highlights);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveProgress() {
  final authService = Provider.of<AuthFirebaseService>(context, listen: false);
    final bookService = Provider.of<BookService>(context, listen: false);
    
  if (authService.currentUser != null) {
      final readingTime = DateTime.now().difference(_readingStartTime);
      
      bookService.updateReadingProgress(
        bookId: widget.book.id,
    userId: authService.currentUser!.uid,
        currentPage: _currentPage,
        totalPages: widget.book.pageCount,
        additionalReadingTime: readingTime,
  bookmarks: _bookmarks,
  highlights: _highlights,
      );
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= widget.book.pageCount) {
      setState(() {
        _currentPage = page;
      });
      _pageController.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < widget.book.pageCount) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showControls
          ? AppBar(
              title: Text(widget.book.title),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bookmark_add),
                  onPressed: () {
                    // TODO: إضافة علامة مرجعية
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تمت إضافة علامة مرجعية'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _showSettingsDialog();
                  },
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index + 1;
            });
          },
          itemCount: widget.book.pageCount,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _getPageContent(index + 1),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  if (_showControls) _pageNotesBar(index + 1),
                  if (_showControls) ...[
                    const SizedBox(height: 20),
                    Text(
                      'صفحة $_currentPage من ${widget.book.pageCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _showControls
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شريط التقدم
                    Row(
                      children: [
                        Text(
                          '$_currentPage',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentPage.toDouble(),
                            min: 1,
                            max: widget.book.pageCount.toDouble(),
                            divisions: widget.book.pageCount - 1,
                            onChanged: (value) {
                              _goToPage(value.round());
                            },
                          ),
                        ),
                        Text(
                          '${widget.book.pageCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // أزرار التحكم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 32,
                        ),
                        IconButton(
                          onPressed: () {
                            _showPageJumpDialog();
                          },
                          icon: const Icon(Icons.list),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: () {
                            _showBookmarkDialog();
                          },
                          icon: const Icon(Icons.bookmark),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: () {
                            _shareCurrentPage();
                          },
                          icon: const Icon(Icons.share),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: () {
                            _addHighlightDialog();
                          },
                          icon: const Icon(Icons.highlight),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: _currentPage < widget.book.pageCount ? _nextPage : null,
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _pageNotesBar(int page) {
    final hasBookmark = _bookmarks.containsKey(page.toString());
    final highlights = List<String>.from(_highlights[page.toString()] ?? []);
    if (!hasBookmark && highlights.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBookmark)
            Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _bookmarks[page.toString()]?.toString().isEmpty == true
                        ? 'علامة مرجعية'
                        : _bookmarks[page.toString()].toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة',
                  onPressed: () {
                    setState(() {
                      _bookmarks.remove(page.toString());
                    });
                    _saveProgress();
                  },
                  icon: const Icon(Icons.close, size: 16),
                )
              ],
            ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var i = 0; i < highlights.length; i++)
                  Chip(
                    label: Text(highlights[i], style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() {
                        final list = List<String>.from(highlights);
                        list.removeAt(i);
                        _highlights[page.toString()] = list;
                      });
                      _saveProgress();
                    },
                  )
              ],
            )
          ]
        ],
      ),
    );
  }

  String _getPageContent(int pageNumber) {
    // محتوى تجريبي للصفحات
    final baseContent = '''
هذا محتوى تجريبي للصفحة رقم $pageNumber من كتاب "${widget.book.title}" للمؤلف ${widget.book.author}.

في هذه الصفحة نتناول موضوعاً مهماً يتعلق بمحتوى الكتاب. يحتوي النص على معلومات قيمة ومفيدة للقارئ، ويسعى إلى تقديم المعرفة بطريقة واضحة ومفهومة.

النص مكتوب باللغة العربية ويراعي قواعد الكتابة السليمة. كما يحتوي على فقرات متنوعة تغطي جوانب مختلفة من الموضوع المطروح.

هذا المحتوى مخصص للاختبار فقط، وفي التطبيق الحقيقي سيتم استبداله بالمحتوى الفعلي للكتاب من ملف PDF أو EPUB.

يمكن للقارئ التنقل بين الصفحات باستخدام الأزرار أو السحب، كما يمكنه إضافة علامات مرجعية والتحكم في إعدادات القراءة.

''';

    // إضافة محتوى إضافي لجعل كل صفحة مختلفة قليلاً
    final additionalContent = pageNumber % 3 == 0
        ? '\n\nهذه فقرة إضافية تظهر في الصفحات التي رقمها قابل للقسمة على 3. تحتوي على معلومات خاصة بهذا النوع من الصفحات.'
        : pageNumber % 2 == 0
            ? '\n\nهذه فقرة خاصة بالصفحات الزوجية. تحتوي على محتوى مميز يظهر فقط في هذه الصفحات.'
            : '\n\nهذه فقرة خاصة بالصفحات الفردية. تقدم معلومات إضافية مفيدة للقارئ.';

    return baseContent + additionalContent;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات القراءة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('السطوع'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: تطبيق تغيير السطوع
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('حجم الخط'),
              trailing: DropdownButton<String>(
                value: 'متوسط',
                items: const [
                  DropdownMenuItem(value: 'صغير', child: Text('صغير')),
                  DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                  DropdownMenuItem(value: 'كبير', child: Text('كبير')),
                ],
                onChanged: (value) {
                  // TODO: تطبيق تغيير حجم الخط
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('لون الخلفية'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: تغيير لون الخلفية إلى أبيض
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: تغيير لون الخلفية إلى بيج
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5DC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: تغيير لون الخلفية إلى أسود
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog() {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'رقم الصفحة (1-${widget.book.pageCount})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= widget.book.pageCount) {
                _goToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('رقم الصفحة غير صحيح'),
                  ),
                );
              }
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('العلامات المرجعية'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              if (_bookmarks.isEmpty)
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('لا توجد علامات مرجعية'),
                ),
              ..._bookmarks.entries.map((e) {
                final page = int.tryParse(e.key) ?? 0;
                return ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.amber),
                  title: Text('صفحة $page'),
                  subtitle: e.value.toString().isEmpty ? null : Text(e.value.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _bookmarks.remove(e.key);
                      });
                      Navigator.pop(context);
                      _saveProgress();
                    },
                  ),
                  onTap: () {
                    _goToPage(page);
                    Navigator.pop(context);
                  },
                );
              })
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _bookmarks[_currentPage.toString()] = '';
              });
              _saveProgress();
              Navigator.pop(context);
            },
            child: const Text('إضافة علامة'),
          ),
        ],
      ),
    );
  }

  void _addHighlightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة إبراز'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'النص الذي تريد إبرازه',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              setState(() {
                final list = List<String>.from(_highlights[_currentPage.toString()] ?? []);
                list.add(controller.text.trim());
                _highlights[_currentPage.toString()] = list;
              });
              _saveProgress();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _shareCurrentPage() {
    // TODO: تطبيق مشاركة الصفحة الحالية
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('مشاركة الصفحة $_currentPage من ${widget.book.title}'),
        action: SnackBarAction(
          label: 'نسخ',
          onPressed: () {
            // TODO: نسخ رابط الصفحة
          },
        ),
      ),
    );
  }
}
