import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:scalex_chatbot/features/chat/data/models/message.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  pw.Font? _arabicFont;
  pw.Font? _englishFont;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  // Request storage permissions (IMPORTANT for accessing Downloads)
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Check Android version
      var status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // For Android 13+ (API 33+), try manageExternalStorage
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    }
    return true; // iOS doesn't need these permissions
  }

  // Initialize fonts (simplified)
  Future<void> _initializeFonts() async {
    if (_arabicFont != null && _englishFont != null) return;

    try {
      final arabicFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      _arabicFont = pw.Font.ttf(arabicFontData);

      final englishFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
      _englishFont = pw.Font.ttf(englishFontData);
    } catch (e) {
      print('Error loading fonts: $e');
      // Use built-in fonts as fallback
      _arabicFont = pw.Font.helvetica();
      _englishFont = pw.Font.helvetica();
    }
  }

  // Get PUBLIC Downloads directory that user can easily access
  Future<Directory> _getPublicDirectory() async {
    try {
      if (Platform.isAndroid) {
        // DIRECTLY use the public Downloads folder (no subfolder)
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);

        // Check if Downloads exists
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }

        // Alternative Downloads path
        final altDownloadsPath = '/storage/emulated/0/Downloads';
        final altDownloadsDir = Directory(altDownloadsPath);
        if (await altDownloadsDir.exists()) {
          return altDownloadsDir;
        }

        // Fallback: try Documents folder
        final documentsPath = '/storage/emulated/0/Documents';
        final documentsDir = Directory(documentsPath);
        if (await documentsDir.exists()) {
          return documentsDir;
        }
      }

      // iOS or fallback: use app documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      print('Error getting public directory: $e');
      // Last fallback
      return await getApplicationDocumentsDirectory();
    }
  }

  // Export as PDF (with public storage)
  Future<String> exportAsPdf(List<Message> messages, String language) async {
    if (_isProcessing) {
      throw Exception('Another export is already in progress');
    }

    _isProcessing = true;
    try {
      // Request permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission && Platform.isAndroid) {
        throw Exception('Storage permission is required to save files');
      }

      await _initializeFonts();

      final pdf = pw.Document();
      final isArabic = language == 'ar';

      // Add pages (split if needed)
      final chunks = _chunkMessages(messages, 15); // 15 messages per page

      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => _buildPdfContent(chunk, isArabic),
          ),
        );
      }

      // Save to PUBLIC directory
      final directory = await _getPublicDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ChatExport_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      // Make sure file is readable by other apps
      if (Platform.isAndroid) {
        await Process.run('chmod', ['644', file.path]);
      }

      print('PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('PDF export error: $e');
      throw Exception('Failed to export PDF: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  // Chunk messages for pagination
  List<List<Message>> _chunkMessages(List<Message> messages, int chunkSize) {
    final chunks = <List<Message>>[];
    for (var i = 0; i < messages.length; i += chunkSize) {
      final end = (i + chunkSize < messages.length) ? i + chunkSize : messages.length;
      chunks.add(messages.sublist(i, end));
    }
    return chunks;
  }

  // Build PDF content (simplified)
  pw.Widget _buildPdfContent(List<Message> messages, bool isArabic) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Text(
          isArabic ? 'Chat Export' : 'Chat Export',
          style: pw.TextStyle(
            font: _englishFont,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 10),

        // Messages
        ...messages.map((message) => _buildMessageWidget(message, isArabic)).toList(),
      ],
    );
  }

  // Build single message widget
  pw.Widget _buildMessageWidget(Message message, bool isArabic) {
    final sender = message.isUser ? 'You' : 'Assistant';
    final bgColor = message.isUser ? PdfColors.blue50 : PdfColors.grey100;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sender,
            style: pw.TextStyle(
              font: _englishFont,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            message.content,
            style: pw.TextStyle(
              font: _containsArabic(message.content) ? _arabicFont : _englishFont,
              fontSize: 10,
            ),
          ),
          if (message.timestamp != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              _formatTime(message.timestamp!),
              style: pw.TextStyle(
                font: _englishFont,
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Export as text file (with public storage)
  Future<String> exportAsText(List<Message> messages, String language) async {
    if (_isProcessing) {
      throw Exception('Another export is already in progress');
    }

    _isProcessing = true;
    try {
      // Request permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission && Platform.isAndroid) {
        throw Exception('Storage permission is required to save files');
      }

      final content = _formatMessagesAsText(messages, language);
      final directory = await _getPublicDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ChatExport_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(content);

      // Make sure file is readable by other apps
      if (Platform.isAndroid) {
        await Process.run('chmod', ['644', file.path]);
      }

      print('Text file saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Text export error: $e');
      throw Exception('Failed to export text: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  // Format messages as text
  String _formatMessagesAsText(List<Message> messages, String language) {
    final isArabic = language == 'ar';
    final buffer = StringBuffer();

    buffer.writeln('CHAT EXPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Messages: ${messages.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final message in messages) {
      final sender = message.isUser ? 'You' : 'Assistant';
      final time = message.timestamp != null
          ? _formatTime(message.timestamp!)
          : 'No timestamp';

      buffer.writeln('[$sender] - $time');
      buffer.writeln(message.content);
      if (!message.isUser && message.aiModel != null) {
        buffer.writeln('Model: ${message.aiModel}');
      }
      buffer.writeln('-' * 50);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Share file with proper content URI for Android
  Future<void> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found at: $filePath');
      }

      // Verify file is readable
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File is empty');
      }

      print('Sharing file: $filePath (${bytes.length} bytes)');

      // Use XFile with explicit mime type
      final xFile = XFile(
        filePath,
        mimeType: filePath.endsWith('.pdf')
            ? 'application/pdf'
            : 'text/plain',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'Chat Export',
        text: 'Sharing my chat export',
      );
    } catch (e) {
      print('Share error: $e');
      throw Exception('Failed to share file: ${e.toString()}');
    }
  }

  // Utility: Check if text contains Arabic
  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  // Utility: Format timestamp
  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  // Get file info
  Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      final kb = bytes / 1024;

      if (kb < 1024) {
        return '${kb.toStringAsFixed(1)} KB';
      } else {
        return '${(kb / 1024).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> getFileLocation(String filePath) async {
    try {
      return File(filePath).parent.path;
    } catch (e) {
      return 'Unknown';
    }
  }

  // Helper method to get user-friendly location description
  String getFriendlyLocation() {
    if (Platform.isAndroid) {
      return 'Download';
    }
    return 'Documents';
  }
}