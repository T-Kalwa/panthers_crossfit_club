import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'save_helper.dart'
    if (dart.library.html) 'save_helper_web.dart'
    if (dart.library.io) 'save_helper_mobile.dart';

class DemoUtils {
  static Future<void> shareWidgetAsImage(GlobalKey boundaryKey, String fileName) async {
    final bytes = await _capturePng(boundaryKey);
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/$fileName.png').create();
    await imagePath.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(imagePath.path)], text: 'Voici votre Pass Panthers Club !');
  }

  static Future<bool> saveToGallery(GlobalKey boundaryKey, String fileName) async {
    final bytes = await _capturePng(boundaryKey);
    if (bytes == null) return false;

    // Utilisation de l'import conditionnel via SaveHelper
    return await SaveHelper.saveImage(bytes, fileName);
  }

  static Future<Uint8List?> _capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture Error: $e');
      return null;
    }
  }

  static Future<void> shareText(String text, String fileName) async {
    try {
      // Try to share as a file for better readability
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.txt');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport Panthers CrossFit Club');
    } catch (e) {
      // Fallback: share as plain text
      await Share.share(text, subject: 'Rapport Panthers CrossFit Club');
    }
  }
}
