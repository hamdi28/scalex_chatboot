import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:scalex_chatbot/features/chat/data/models/message.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';

/// Service class for exporting chat messages as PDF or text files and sharing them.
class ExportService {
  pw.Font? _arabicFont;
  pw.Font? _englishFont;
  bool _isProcessing = false;

  /// Indicates whether an export operation is in progress.
  bool get isProcessing => _isProcessing;

  /// Requests storage permissions on Android devices.
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isGranted) return true;

      status = await Permission.storage.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return status.isGranted;
    }
    return true; // iOS does not require these permissions
  }

  /// Initializes the Arabic and English fonts for PDF export.
  Future<void> _initializeFonts() async {
    if (_arabicFont != null && _englishFont != null) return;

    try {
      final arabicFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      _arabicFont = pw.Font.ttf(arabicFontData);

      final englishFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
      _englishFont = pw.Font.ttf(englishFontData);
    } catch (_) {
      _arabicFont = pw.Font.helvetica();
      _englishFont = pw.Font.helvetica();
    }
  }

  /// Returns a public directory suitable for saving files.
  Future<Directory> _getPublicDirectory() async {
    try {
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) return downloadsDir;

        final altDownloadsDir = Directory('/storage/emulated/0/Downloads');
        if (await altDownloadsDir.exists()) return altDownloadsDir;

        final documentsDir = Directory('/storage/emulated/0/Documents');
        if (await documentsDir.exists()) return documentsDir;
      }
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Exports [messages] as a PDF file in the specified [language].
  Future<String> exportAsPdf(List<Message> messages, String language) async {
    if (_isProcessing) throw Exception('Another export is already in progress');
    _isProcessing = true;

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission && Platform.isAndroid) {
        throw Exception('Storage permission is required to save files');
      }

      await _initializeFonts();
      final pdf = pw.Document();
      final isArabic = language == 'ar';

      final chunks = _chunkMessages(messages, 15);

      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => _buildPdfContent(chunk, isArabic),
          ),
        );
      }

      final directory = await _getPublicDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ChatExport_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      if (Platform.isAndroid) {
        await Process.run('chmod', ['644', file.path]);
      }

      return file.path;
    } catch (e) {
      throw Exception('Failed to export PDF: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  /// Chunks messages into smaller lists of [chunkSize] for pagination.
  List<List<Message>> _chunkMessages(List<Message> messages, int chunkSize) {
    final chunks = <List<Message>>[];
    for (var i = 0; i < messages.length; i += chunkSize) {
      final end = (i + chunkSize < messages.length) ? i + chunkSize : messages.length;
      chunks.add(messages.sublist(i, end));
    }
    return chunks;
  }

  /// Builds PDF content for a list of [messages].
  pw.Widget _buildPdfContent(List<Message> messages, bool isArabic) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
        ...messages.map((message) => _buildMessageWidget(message, isArabic)).toList(),
      ],
    );
  }

  /// Builds a PDF widget for a single [message].
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

  /// Exports [messages] as a text file in the specified [language].
  Future<String> exportAsText(List<Message> messages, String language) async {
    if (_isProcessing) throw Exception('Another export is already in progress');
    _isProcessing = true;

    try {
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

      if (Platform.isAndroid) {
        await Process.run('chmod', ['644', file.path]);
      }

      return file.path;
    } catch (e) {
      throw Exception('Failed to export text: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  /// Formats [messages] as plain text for export.
  String _formatMessagesAsText(List<Message> messages, String language) {
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

  /// Shares a file at [filePath] using the system share dialog.
  Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at: $filePath');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('File is empty');
    }

    final xFile = XFile(
      filePath,
      mimeType: filePath.endsWith('.pdf') ? 'application/pdf' : 'text/plain',
    );

    await Share.shareXFiles(
      [xFile],
      subject: 'Chat Export',
      text: 'Sharing my chat export',
    );
  }

  /// Checks if [text] contains Arabic characters.
  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Formats [dateTime] to a human-readable string.
  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Returns the size of a file at [filePath] in KB or MB.
  Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      final kb = bytes / 1024;
      if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Returns the parent directory of the file at [filePath].
  Future<String> getFileLocation(String filePath) async {
    try {
      return File(filePath).parent.path;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Returns a user-friendly name for the default file location.
  String getFriendlyLocation() {
    if (Platform.isAndroid) return 'Download';
    return 'Documents';
  }
}
