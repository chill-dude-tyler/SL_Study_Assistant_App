// FILE: lib/services/ocr_service.dart
// Wraps tesseract_ocr for image-to-text extraction.
// Supports English, Sinhala, and Tamil language packs.

import 'package:tesseract_ocr/tesseract_ocr.dart';

class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  // Tesseract language codes
  static const Map<String, String> _langCodes = {
    'en': 'eng',
    'si': 'sin',
    'ta': 'tam',
  };

  bool _isInitialised = false;

  Future<void> initialise() async {
    if (_isInitialised) return;
    // Tesseract initialises lazily on first use
    _isInitialised = true;
  }

  /// Extract text from an image file at [imagePath].
  /// [language] is the app language code: 'en', 'si', or 'ta'.
  Future<OcrResult> extractText(
    String imagePath, {
    String language = 'en',
  }) async {
    await initialise();

    final tessLang = _langCodes[language] ?? 'eng';

    try {
      final text = await TesseractOcr.extractText(
        imagePath,
        language: tessLang,
        args: {
          'psm': '3',   // Fully automatic page segmentation
          'oem': '3',   // Default OCR engine mode
        },
      );

      if (text == null || text.trim().isEmpty) {
        return OcrResult(
          success: false,
          text: '',
          errorMessage: 'No text found in image.',
        );
      }

      return OcrResult(
        success: true,
        text: text.trim(),
        wordCount: _countWords(text),
      );
    } catch (e) {
      return OcrResult(
        success: false,
        text: '',
        errorMessage: 'OCR failed: ${e.toString()}',
      );
    }
  }

  /// Extract text from multiple images and combine.
  Future<OcrResult> extractFromMultiple(
    List<String> imagePaths, {
    String language = 'en',
  }) async {
    final buffer = StringBuffer();
    int totalWords = 0;

    for (final path in imagePaths) {
      final result = await extractText(path, language: language);
      if (result.success && result.text.isNotEmpty) {
        buffer.writeln(result.text);
        buffer.writeln(); // page separator
        totalWords += result.wordCount;
      }
    }

    final combined = buffer.toString().trim();
    return OcrResult(
      success: combined.isNotEmpty,
      text: combined,
      wordCount: totalWords,
      errorMessage: combined.isEmpty ? 'No text extracted from any image.' : null,
    );
  }

  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }
}

/// Result object returned by OcrService
class OcrResult {
  final bool success;
  final String text;
  final int wordCount;
  final String? errorMessage;

  OcrResult({
    required this.success,
    required this.text,
    this.wordCount = 0,
    this.errorMessage,
  });
}
