import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class SaveHelper {
  static Future<bool> saveImage(Uint8List bytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/$fileName.png').create();
      await imagePath.writeAsBytes(bytes);
      
      await Gal.putImage(imagePath.path, album: 'Panthers Club');
      return true;
    } catch (e) {
      debugPrint('Gal Error: $e');
      return false;
    }
  }
}
