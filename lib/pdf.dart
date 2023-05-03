import 'dart:io' show Platform;
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_text_extraction/pdf_text_extraction.dart';

var pdfLib = PDFToTextWrapping();

class PDF {
  String path;
  String text;
  PDF(this.path, this.text);
}

Future<String> readPDF(String path) async {
  if (Platform.isAndroid || Platform.isIOS) {
    //pdf_text package
    final document = await PDFDoc.fromPath(path);
    return await document.text;
  } else if (Platform.isWindows || Platform.isLinux) {
    //pdf_text_extraction package
    return pdfLib.extractText(path);
  } else {
    return "Platform not supported";
  }
}
