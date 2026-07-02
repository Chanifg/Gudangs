import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int sizeBytes;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.sizeBytes,
  });
}

class UpdateService {
  static const _channel = MethodChannel('com.gudangs.gudangs/apk_installer');
  static const _githubRepo = 'Chanifg/Gudangs';

  // Check if a new version is available on GitHub
  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest');
      final request = await client.getUrl(uri);
      
      // GitHub API requires a User-Agent header
      request.headers.set(HttpHeaders.userAgentHeader, 'GudangsApp-Updater');
      
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final String tagName = json['tag_name'] as String? ?? '';
      if (tagName.isEmpty || !_isNewerVersion(currentVersion, tagName)) {
        return null;
      }

      // Find the first APK asset
      final assets = json['assets'] as List<dynamic>? ?? [];
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkAsset = asset as Map<String, dynamic>;
          break;
        }
      }

      if (apkAsset == null) {
        return null;
      }

      final String downloadUrl = apkAsset['browser_download_url'] as String? ?? '';
      final int size = apkAsset['size'] as int? ?? 0;
      final String releaseNotes = json['body'] as String? ?? '';

      return UpdateInfo(
        latestVersion: tagName,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        sizeBytes: size,
      );
    } catch (e) {
      // Fail silently
      return null;
    } finally {
      client.close();
    }
  }

  // Download the APK and report progress
  static Future<File?> downloadApk(String url, Function(double progress) onProgress) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final totalBytes = response.contentLength;
      int downloadedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/update.apk');
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final fileSink = apkFile.openWrite();
      await for (final chunk in response) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await fileSink.flush();
      await fileSink.close();
      return apkFile;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  // Trigger installation via Kotlin platform channel
  static Future<bool> installApk(String filePath) async {
    try {
      final bool result = await _channel.invokeMethod('installApk', {'filePath': filePath});
      return result;
    } catch (e) {
      return false;
    }
  }

  // Compare semantic versions (e.g. 1.2.0 vs v1.3.0)
  static bool _isNewerVersion(String current, String latest) {
    String clean(String v) => v.replaceAll(RegExp(r'[^0-9.]'), '');
    final cParts = clean(current).split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final lParts = clean(latest).split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < lParts.length; i++) {
      if (i >= cParts.length) return true;
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    return false;
  }
}
