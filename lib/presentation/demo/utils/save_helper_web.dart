import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SaveHelper {
  static Future<bool> saveImage(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.png")
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  }
}
