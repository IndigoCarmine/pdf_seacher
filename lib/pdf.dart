import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_text_extraction/pdf_text_extraction.dart';
import 'package:text_analysis/text_analysis.dart';

class AnalyzeData {
  String text;
  String term;
  AnalyzeData(this.text, this.term);
}

class PDF {
  String path;
  String text;
  late String abstract;
  Future<TextDocument>? textDocument;
  bool isSelected = false;
  PDF(this.path, this.text) {
    abstract = text.length > 100 ? text.substring(0, 100) : text;
    abstract = text.length == 0
        ? "No text found. It may consist only of images."
        : abstract;
  }
  Future<double> getRAKEScore(String term) async {
    analyzeText();
    TextDocument doc = await textDocument!;
    return doc.keywords.keywordScores[term] ?? 0;
  }

  Future<int> seachTerm(String term) async {
    //seach term in text
    int count = 0;
    for (int i = 0; i < text.length - term.length; i++) {
      if (text.substring(i, i + term.length) == term) {
        count++;
        if (count == 2 ^ 53) return count;
      }
    }
    return count;
  }

  void analyzeText() {
    textDocument ??= compute(_analyzeText, text, debugLabel: "text_analysis");
  }

  static Future<TextDocument> _analyzeText(String text) async {
    TextDocument doc = await TextDocument.analyze(
        sourceText: text,
        analyzer: English.analyzer,
        nGramRange: const NGramRange(1, 3));
    return doc;
  }
}

Future<String> readPDF(String path) async {
  return compute(_readPDF, path, debugLabel: "pdf_text");
}

Future<String> _readPDF(String path) async {
  if (Platform.isAndroid || Platform.isIOS) {
    //pdf_text package
    final document = await PDFDoc.fromPath(path);
    return await document.text;
  } else if (Platform.isWindows || Platform.isLinux) {
    //pdf_text_extraction package
    try {
      final pdfLib = PDFTextExtractionWrapping();
      return pdfLib.extractText(path);
    } catch (e) {
      return e.toString();
    }
  } else {
    return "Platform not supported";
  }
}
