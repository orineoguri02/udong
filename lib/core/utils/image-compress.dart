import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// 업로드용 이미지를 WebP로 압축한다.
///
/// - 모바일: 파일 경로를 그대로 네이티브 압축기에 넘긴다.
/// - 웹: image_picker가 `blob:` URL을 주고 `compressWithFile`이 지원되지 않으므로
///   바이트로 읽어 `compressWithList`(canvas 기반)로 압축한다.
Future<Uint8List?> compressImageToWebp(String imagePath) async {
  if (kIsWeb) {
    final bytes = await XFile(imagePath).readAsBytes();
    return FlutterImageCompress.compressWithList(
      bytes,
      quality: 75,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.webp,
    );
  }
  return FlutterImageCompress.compressWithFile(
    imagePath,
    quality: 75,
    minWidth: 1024,
    minHeight: 1024,
    format: CompressFormat.webp,
  );
}

/// 선택한 로컬 이미지가 존재하는지 확인한다. 웹의 `blob:` URL은 항상 존재한다고 본다.
Future<bool> localImageExists(String imagePath) async {
  if (kIsWeb) return true;
  return File(imagePath).exists();
}
