// ============================================================
// EduAcademy - تصدير الشهادة كصورة PNG وحفظها/مشاركتها فعلياً
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File, Directory;

class CertificateExporter {
  /// يحوّل الـ Widget داخل RepaintBoundary إلى بايتات PNG
  static Future<Uint8List> capture(GlobalKey key) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// يحفظ الصورة في جهاز المستخدم ويعيد مسار الملف (null على الويب)
  static Future<String?> saveToDevice(Uint8List bytes, String fileName) async {
    if (kIsWeb) return null;
    Directory dir;
    try {
      // مجلد التنزيلات على أندرويد (مرئي للمستخدم)
      final ext = await getExternalStorageDirectory();
      dir = ext ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// مشاركة/تنزيل الصورة عبر نافذة المشاركة الأصلية (أندرويد/ويب)
  static Future<void> share(
    Uint8List bytes,
    String fileName,
    String text,
  ) async {
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: fileName, mimeType: 'image/png')],
      text: text,
      fileNameOverrides: [fileName],
    );
  }
}
