/// Web implementation: triggers download via data URL (used for web only).
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';

@JS('eval')
external void jsEval(String code);

Future<void> downloadFile(List<int> bytes, String format) async {
  try {
    final base64Bytes = base64Encode(bytes);
    final mimeType = format == 'xls' ? 'application/vnd.ms-excel' : 'text/csv';
    final dataUrl = 'data:$mimeType;base64,$base64Bytes';
    final filename =
        'export_${DateTime.now().toIso8601String().replaceAll(RegExp(r"[:.-]"), '_')}.$format';

    jsEval("""
      (function() {
        const link = document.createElement('a');
        link.href = '$dataUrl';
        link.download = '$filename';
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })();
    """);
  } catch (e) {
    debugPrint('[DownloadHelper] Error on web download: $e');
    rethrow;
  }
}