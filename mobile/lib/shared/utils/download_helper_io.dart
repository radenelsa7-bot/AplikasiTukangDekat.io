/// Non-web implementation: saves file using path_provider (used for Android/iOS/desktop).
library;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

Future<void> downloadFile(List<int> bytes, String format) async {
  try {
    final folder = await getApplicationDocumentsDirectory();
    final extension = format == 'xls' ? 'xls' : 'csv';
    final filename =
        'export_${DateTime.now().toIso8601String().replaceAll(RegExp(r"[:.-]"), '_')}.$extension';
    final file = File('${folder.path}/$filename');
    await file.writeAsBytes(bytes);
  } catch (e) {
    debugPrint('[DownloadHelper] Error saving file: $e');
    rethrow;
  }
}