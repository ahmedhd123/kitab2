import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:epub_viewer/epub_viewer.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';

class BookReaderScreen extends StatefulWidget {
  final BookModel? book;
  
  const BookReaderScreen({Key? key, this.book}) : super(key: key);

  @override
  _BookReaderScreenState createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  String? _localFilePath;
  int _currentPage = 1;
  int _totalPages = 0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _downloadAndOpenBook();
    }
  }

  Future<void> _downloadAndOpenBook() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // تنزيل الملف إذا لم يكن موجوداً محلياً
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${widget.book!.id}.${widget.book!.fileType}';
      final localFile = File('${directory.path}/$fileName');

      if (!await localFile.exists()) {
        // لأغراض التجربة، سنتجاهل التحميل الفعلي
        // يمكن إضافة ملفات تجريبية في مجلد assets
        throw 'ميزة تحميل الكتب قيد التطوير';
      }

      setState(() {
        _localFilePath = localFile.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الكتاب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateProgress() {
    if (_totalPages > 0) {
      final newProgress = _currentPage / _totalPages;
      if (newProgress != _progress) {
        setState(() {
          _progress = newProgress;
        });

        // حفظ التقدم في القراءة
        final authService = Provider.of<AuthService>(context, listen: false);
        final bookService = Provider.of<BookService>(context, listen: false);
        
        if (authService.currentUser != null && widget.book != null) {
          bookService.updateReadingProgress(
            authService.currentUser!.uid,
            widget.book!.id,
            newProgress,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('قارئ الكتب')),
        body: const Center(
          child: Text('لم يتم تحديد كتاب للقراءة'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              // TODO: إضافة علامة مرجعية
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showReaderSettings();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localFilePath == null
              ? const Center(child: Text('فشل في تحميل الكتاب'))
              : _buildReader(),
      bottomNavigationBar: _localFilePath != null ? _buildBottomControls() : null,
    );
  }

  Widget _buildReader() {
    if (widget.book!.fileType.toLowerCase() == 'pdf') {
      return _buildPDFReader();
    } else if (widget.book!.fileType.toLowerCase() == 'epub') {
      return _buildEPUBReader();
    } else {
      return const Center(
        child: Text('نوع الملف غير مدعوم'),
      );
    }
  }

  Widget _buildPDFReader() {
    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage - 1,
      fitPolicy: FitPolicy.WIDTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = (page ?? 0) + 1;
        });
        _updateProgress();
      },
      onError: (error) {
        print('خطأ في PDF: $error');
      },
    );
  }

  Widget _buildEPUBReader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'قارئ EPUB',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'ميزة قراءة EPUB قيد التطوير',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: تنفيذ قارئ EPUB
            },
            child: const Text('فتح الكتاب'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الصفحة السابقة
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage > 1 ? _previousPage : null,
          ),
          
          // معلومات الصفحة
          Text(
            '$_currentPage من $_totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          // الصفحة التالية
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _updateProgress();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _updateProgress();
    }
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إعدادات القراءة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('وضع القراءة الليلي'),
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (value) {
                  // TODO: تغيير السمة
                },
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('حجم النص'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // TODO: تقليل حجم النص
                    },
                  ),
                  const Text('16'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // TODO: زيادة حجم النص
                    },
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة الكتاب'),
              onTap: () {
                Navigator.pop(context);
                _shareBook();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareBook() {
    // TODO: تنفيذ مشاركة الكتاب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة المشاركة قيد التطوير'),
      ),
    );
  }
}
