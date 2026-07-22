/// Non-web implementation: saves file using path_provider (used for Android/iOS/desktop).
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Downloads file to device storage and returns the file path.
/// For mobile, also opens the file automatically using open_filex.
Future<String?> downloadFile(List<int> bytes, String format) async {
  try {
    final folder = await getApplicationDocumentsDirectory();
    final extension = format == 'xls' ? 'xls' : 'csv';
    final filename =
        'export_${DateTime.now().toIso8601String().replaceAll(RegExp(r"[:.-]"), '_')}.$extension';
    final file = File('${folder.path}/$filename');
    await file.writeAsBytes(bytes);

    // Open file automatically on mobile (non-web) platforms
    if (!kIsWeb) {
      final opened = await OpenFilex.open(file.path);
      debugPrint('[DownloadHelper] Open result: $opened');
    }

    return file.path;
  } catch (e) {
    debugPrint('[DownloadHelper] Error saving file: $e');
    rethrow;
  }
}
