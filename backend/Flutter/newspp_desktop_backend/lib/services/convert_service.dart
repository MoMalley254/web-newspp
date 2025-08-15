import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Pdf2HtmlConverter {
  /// Prepares the executable and required data folder.
  /// Returns true if successfully prepared.
  Future<bool> prepareExecutable() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final toolDir = Directory(p.join(supportDir.path, 'pdf2htmlEX'));

      print('📁 Support directory: ${supportDir.path}');
      print('🔧 Tool directory: ${toolDir.path}');

      final exePath = p.join(toolDir.path, 'pdf2htmlEX.exe');
      final dataDirPath = p.join(toolDir.path, 'data');

      final exeFile = File(exePath);

      if (!await exeFile.exists()) {
        print('⚙️ Extracting pdf2htmlEX.exe and data/ folder...');

        await toolDir.create(recursive: true);

        // Extract the .exe
        final exeBytes = await rootBundle.load(
          'assets/bin/windows/pdf2htmlex/pdf2htmlEX.exe',
        );
        await exeFile.writeAsBytes(exeBytes.buffer.asUint8List());

        // Extract the data directory
        final success = await _extractAssetFolder(
          assetPath: 'assets/bin/windows/pdf2htmlex/data/',
          destinationPath: dataDirPath,
        );

        if (!success) {
          throw Exception('❌ Failed to extract asset folder');
        }

        print('✅ Assets extracted to $dataDirPath');
        print('✅ pdf2htmlEX prepared at $exePath');
      } else {
        print('✅ pdf2htmlEX already exists at $exePath');
      }

      return true;
    } catch (e) {
      print('❌ Error preparing executable: $e');
      return false;
    }
  }

  /// Recursively extracts all assets under [assetPath] into [destinationPath].
  Future<bool> _extractAssetFolder({
    required String assetPath,
    required String destinationPath,
  }) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

      final matchingAssets = manifestMap.keys
          .where((String key) => key.startsWith(assetPath))
          .toList();

      for (final asset in matchingAssets) {
        final relativePath = asset.replaceFirst(assetPath, '');
        final filePath = p.join(destinationPath, relativePath);
        final file = File(filePath);
        await file.create(recursive: true);

        final byteData = await rootBundle.load(asset);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      return true;
    } catch (e) {
      print('❌ Error extracting assets: $e');
      return false;
    }
  }
}
