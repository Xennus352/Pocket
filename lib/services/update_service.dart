import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String githubApiUrl =
      'https://api.github.com/repos/Xennus352/Pocket/releases/latest';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get installed app version (e.g. "1.0.0")
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version.replaceAll('v', '').trim();

      // 2. Query GitHub Releases API
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // GitHub tag_name is usually "v2.0.1" or "2.0.1"
        String rawTag = data['tag_name'] ?? '';
        String latestVersion = rawTag.replaceAll('v', '').trim();

        // 3. Find the direct download URL for Pocket.apk from release assets
        List assets = data['assets'] ?? [];
        String? downloadUrl;
        
        for (var asset in assets) {
          if (asset['name'] == 'Pocket.apk') {
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // If Pocket.apk wasn't explicitly matched, fallback to the first asset
        downloadUrl ??= assets.isNotEmpty ? assets[0]['browser_download_url'] : null;

        // 4. Trigger pop-up if versions differ and download URL exists
        if (latestVersion != currentVersion && downloadUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static void _showUpdateDialog(
      BuildContext context, String newVersion, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double progress = 0.0;
        bool downloading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("New Update Available! (v$newVersion)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(downloading
                      ? "Downloading update... ${progress.toInt()}%"
                      : "A new version of Pocket is available. Update now?"),
                  if (downloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress / 100),
                  ]
                ],
              ),
              actions: [
                if (!downloading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Later"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => downloading = true);
                      _executeOtaUpdate(apkUrl, (p) {
                        setState(() => progress = p);
                      });
                    },
                    child: const Text("Update Now"),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  static void _executeOtaUpdate(String url, Function(double) onProgress) {
    try {
      OtaUpdate().execute(url, destinationFilename: 'Pocket.apk').listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            double p = double.tryParse(event.value ?? '0') ?? 0;
            onProgress(p);
          }
        },
      );
    } catch (e) {
      debugPrint("OTA Update Error: $e");
    }
  }
}