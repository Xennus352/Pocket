import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../config/colors.dart';

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      if (!context.mounted) return;
      
      _showLoadingDialog(context, 'Checking for updates...');

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/Xennus352/Pocket/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name']?.toString().replaceFirst('v', '') ?? '';
        final releaseUrl = data['html_url']?.toString() ?? '';
        final assets = data['assets'] as List<dynamic>? ?? [];
        
        // Find APK asset and get its size
        double apkSizeMB = 0;
        String apkDownloadUrl = releaseUrl;
        for (final asset in assets) {
          final name = asset['name']?.toString() ?? '';
          if (name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url']?.toString() ?? releaseUrl;
            final sizeBytes = asset['size'] as int? ?? 0;
            apkSizeMB = sizeBytes / (1024 * 1024);
            break;
          }
        }

        if (_isNewerVersion(latestVersion, currentVersion)) {
          _showUpdateDialog(context, latestVersion, apkDownloadUrl, apkSizeMB);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      // Silently fail - no update check is better than crashing
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final l = latestParts.length > i ? (latestParts[i] ?? 0) : 0;
      final c = currentParts.length > i ? (currentParts[i] ?? 0) : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F7FFF)),
            ),
            const SizedBox(width: 16),
            Text(message, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  static void _showUpdateDialog(BuildContext context, String version, String url, double apkSizeMB) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt_rounded, color: Color(0xFF4F7FFF), size: 28),
            SizedBox(width: 12),
            Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version $version is available.'),
            const SizedBox(height: 12),
            if (apkSizeMB > 0)
              Text(
                'Download size: ${apkSizeMB.toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F7FFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(url);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}