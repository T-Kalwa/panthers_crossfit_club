import 'dart:typed_data';
import 'package:flutter/material.dart';

abstract class SaveHelper {
  static Future<bool> saveImage(Uint8List bytes, String fileName) async {
    throw UnsupportedError('Platform not supported');
  }
}
