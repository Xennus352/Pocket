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
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version.replaceAll('v', '').trim();

      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String rawTag = data['tag_name'] ?? '';
        String latestVersion = rawTag.replaceAll('v', '').trim();

        List assets = data['assets'] ?? [];
        String? downloadUrl;

        for (var asset in assets) {
          if (asset['name'] == 'Pocket.apk') {
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        downloadUrl ??= assets.isNotEmpty ? assets[0]['browser_download_url'] : null;

        if (_isNewerVersion(latestVersion, currentVersion) && downloadUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final parts2 = v2.split('.').map(int.tryParse).map((e) => e ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  static bool _isNewerVersion(String latest, String current) {
    return _compareVersions(latest, current) > 0;
  }

  static void _showUpdateDialog(
      BuildContext context, String newVersion, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double progress = 0.0;
        bool downloading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("New Update Available! (v$newVersion)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage ??
                      (downloading
                          ? "Downloading update... ${progress.toInt()}%"
                          : "A new version of Pocket is available. Update now?")),
                  if (downloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress / 100),
                  ],
                ],
              ),
              actionsPadding: EdgeInsets.zero,
              actions: [
                if (!downloading && errorMessage == null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Later"),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            downloading = true;
                            errorMessage = null;
                          });
                          _executeOtaUpdate(apkUrl, (p) {
                            if (context.mounted) {
                              setState(() => progress = p);
                            }
                          }, (error) {
                            if (context.mounted) {
                              setState(() {
                                downloading = false;
                                errorMessage = error;
                              });
                            }
                          }, () {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          });
                        },
                        child: const Text("Update Now"),
                      ),
                    ],
                  ),
                ] else if (errorMessage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              downloading = false;
                              errorMessage = null;
                            });
                          },
                          child: const Text("Retry"),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Later"),
                      ),
                    ],
                  ),
                ] else if (downloading) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          OtaUpdate().cancel();
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  static void _executeOtaUpdate(String url, Function(double) onProgress,
      Function(String) onError, VoidCallback onSuccess) {
    try {
      OtaUpdate().execute(url, destinationFilename: 'Pocket.apk').listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              double p = double.tryParse(event.value ?? '0') ?? 0;
              onProgress(p);
              break;
            case OtaStatus.INSTALLING:
              onProgress(100);
              break;
            case OtaStatus.INSTALLATION_DONE:
              onSuccess();
              break;
            case OtaStatus.INSTALLATION_ERROR:
              onError("Installation failed. Please try again.");
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              onError("Storage permission not granted. Please enable in settings.");
              break;
            case OtaStatus.DOWNLOAD_ERROR:
              onError("Download failed. Check your connection.");
              break;
            case OtaStatus.CHECKSUM_ERROR:
              onError("File integrity check failed.");
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              onError("Update already in progress.");
              break;
            case OtaStatus.INTERNAL_ERROR:
              onError("Update failed: ${event.value ?? 'Unknown error'}");
              break;
            case OtaStatus.CANCELED:
              break;
          }
        },
        onError: (e) {
          onError("Update error: $e");
        },
        onDone: () {},
      );
    } catch (e) {
      onError("Failed to start update: $e");
    }
  }
}