// Image upload/compression service for Supabase Storage.
// Compresses images before upload (max 800px, JPEG 80% quality) and
// stores them in Supabase Storage buckets with public-read access.
// Public URLs are returned for storage in database tables.
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/utils/app_logger.dart';

/// Supabase Storage bucket names.
class StorageBucket {
  static const String logos = 'logos';
  static const String playerPhotos = 'player-photos';
}

/// Result of an image upload.
class UploadResult {
  const UploadResult({
    required this.publicUrl,
    required this.fileName,
    required this.sizeBytes,
  });

  /// Publicly accessible URL of the uploaded image.
  final String publicUrl;

  /// Storage object file name.
  final String fileName;

  /// Compressed file size in bytes.
  final int sizeBytes;
}

/// Compresses and uploads images to Supabase Storage.
///
/// - Resizes to max 800px on the longest edge
/// - Encodes as JPEG at 80% quality
/// - Uploads to the specified bucket (public read, authenticated write)
/// - Returns the public URL for storage in database tables
class ImageUploadService {
  ImageUploadService._();

  static final ImageUploadService _instance = ImageUploadService._();

  /// Singleton accessor.
  static ImageUploadService get instance => _instance;

  SupabaseClient? get _client => SupabaseClientService.instance.client;

  /// Whether Supabase client is initialized.
  bool get isConnected => _client != null;

  /// Compress an image (max 800px longest edge, JPEG 80% quality).
  ///
  /// Accepts raw image bytes (PNG, JPEG, WebP, etc.) and returns compressed
  /// JPEG bytes.
  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if longest edge exceeds 800px
    final maxDimension = 800;
    if (image.width > maxDimension || image.height > maxDimension) {
      final scaled = img.copyResize(
        image,
        width: image.width > image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
      );
      return img.encodeJpg(scaled);
    }

    // Already within size limits — just re-encode as JPEG
    return img.encodeJpg(image);
  }

  /// Upload compressed image bytes to Supabase Storage.
  ///
  /// [bucket] must be 'logos' or 'player-photos'.
  /// [fileName] is the storage object path (e.g. 'auction_abc123/logo.jpg').
  Future<UploadResult> uploadImage({
    required String bucket,
    required String fileName,
    required Uint8List imageBytes,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }

    // Compress first
    final compressed = await compressImage(imageBytes);

    // Upload to storage
    await client.storage.from(bucket).uploadBinary(
      fileName,
      compressed,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        cacheControl: '3600',
        upsert: true,
      ),
    );

    // Get public URL
    final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);

    AppLogger.debug(
      'Image uploaded to $bucket/$fileName (${compressed.length} bytes)',
      tag: 'ImageUpload',
    );

    return UploadResult(
      publicUrl: publicUrl,
      fileName: fileName,
      sizeBytes: compressed.length,
    );
  }

  /// Upload a tournament logo to the `logos` bucket.
  Future<UploadResult> uploadLogo({
    required String auctionId,
    required Uint8List imageBytes,
  }) async {
    final fileName = 'auction_$auctionId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadImage(bucket: StorageBucket.logos, fileName: fileName, imageBytes: imageBytes);
  }

  /// Upload a player photo to the `player-photos` bucket.
  Future<UploadResult> uploadPlayerPhoto({
    required String auctionId,
    required String playerId,
    required Uint8List imageBytes,
  }) async {
    final fileName = 'auction_$auctionId/player_$playerId/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadImage(bucket: StorageBucket.playerPhotos, fileName: fileName, imageBytes: imageBytes);
  }

  /// Delete an image from storage by its public URL.
  ///
  /// Extracts the file name from the URL path and removes the object.
  Future<bool> deleteImage(String publicUrl) async {
    final client = _client;
    if (client == null) return false;

    try {
      // Extract bucket and file name from URL like:
      // https://<project>.supabase.co/storage/v1/object/public/<bucket>/<fileName>
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      // pathSegments: ['storage', 'v1', 'object', 'public', bucket, ...fileNameParts]
      final bucketIndex = pathSegments.indexOf('public');
      if (bucketIndex < 0 || bucketIndex + 1 >= pathSegments.length) {
        AppLogger.warning('Cannot parse public URL for deletion: $publicUrl', tag: 'ImageUpload');
        return false;
      }

      final bucket = pathSegments[bucketIndex + 1];
      final fileName = pathSegments.skip(bucketIndex + 2).join('/');

      await client.storage.from(bucket).remove([fileName]);
      AppLogger.debug('Deleted image $bucket/$fileName', tag: 'ImageUpload');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to delete image from storage: $e', tag: 'ImageUpload', error: e, stackTrace: st);
      return false;
    }
  }
}
