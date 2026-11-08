import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/utils/image-compress.dart';

String _basename(String rawPath) {
  final normalized = rawPath.replaceAll('\\', '/');
  final withoutQuery = normalized.split('?').first;
  final parts = withoutQuery.split('/');
  return parts.isEmpty ? '' : parts.last.trim();
}

String _basenameWithoutExtension(String filename) {
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex <= 0) return filename.trim();
  return filename.substring(0, dotIndex).trim();
}

String homeToImageFilename(String rawImage) {
  final trimmed = rawImage.trim();
  if (trimmed.isEmpty) return 'photo.webp';
  final name = _basename(trimmed);
  final base = _basenameWithoutExtension(name);
  if (base.isEmpty) return 'photo.webp';
  return '$base.webp';
}

bool homeIsRemoteImageUrl(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

Future<(List<int> bytes, String filename)> homeCompressedImageBytesAndFilename(
  String imagePath,
) async {
  final compressed = await compressImageToWebp(imagePath);

  if (compressed != null) {
    final filename = '${_basenameWithoutExtension(_basename(imagePath))}.webp';
    return (compressed, filename);
  }

  throw Exception('이미지를 WebP로 변환하지 못했습니다.');
}

Future<MultipartFile> homeCompressedImagePart(String imagePath) async {
  final (compressed, filename) = await homeCompressedImageBytesAndFilename(
    imagePath,
  );
  return MultipartFile.fromBytes(
    compressed,
    filename: filename,
    contentType: MediaType('image', 'webp'),
  );
}
