import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JsonStorageService {
  final String fileName;

  JsonStorageService(this.fileName);

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<dynamic> readJson() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      return null;
    }
  }

  Future<File> writeJson(dynamic data) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(data));
  }

  // Helper for initial mock data
  Future<void> seedInitialData(dynamic data) async {
    final file = await _localFile;
    if (!await file.exists()) {
      await writeJson(data);
    }
  }
}
