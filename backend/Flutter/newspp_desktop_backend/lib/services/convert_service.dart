import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Pdf2HtmlConverter {
  /// Prepares the executable and required data folder
  /// Returns the path to the extracted directory (containing pdf2htmlEX.exe and data/)
  Future<bool> prepareExecutable() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final toolDir = Directory(p.join(supportDir.path, 'pdf2htmlEX'));

      print('Support directory $supportDir');
      print('Tools directory $toolDir');

      final exePath = p.join(toolDir.path, 'pdf2htmlEX.exe');
      final dataDirPath = p.join(toolDir.path, 'data');

      if (!await File(exePath).exists()) {
        //Doesn't exist
        print('🔧 Extracting pdf2htmlEX.exe and data/ folder...');

        // Create tool directory if not exists
        await toolDir.create(recursive: true);

        // Extract the .exe
        final exeBytes = await rootBundle.load(
          'assets/bin/windows/pdf2htmlex/pdf2htmlEX.exe',
        );
        await File(exePath).writeAsBytes(exeBytes.buffer.asUint8List());

        // Recursively extract data/ directory
        bool hasAssets = await _extractAssetFolder(
          assetPath: 'assets/bin/windows/pdf2htmlex/data/',
          destinationPath: dataDirPath,
        );

        !hasAssets
            ? print('Unable to extract assets')
            : print('Assets extracted');

        print('✅ pdf2htmlEX prepared at $exePath');
      } else {
        //Already exist
        print('✅ pdf2htmlEX already prepared.');
      }
      return true;
    } catch (error) {
      print('Error preparing executable $error');
      return false;
    }
  }

  Future<bool> _extractAssetFolder({
    required String assetPath,
    required destinationPath,
  }) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        jsonDecode(manifestContent),
      );

      final files =
          manifestMap.keys
              .where((String key) => key.startsWith(assetPath))
              .toList();

      for (final asset in files) {
        final relativePath = asset
            .replaceFirst(assetPath, '')
            .replaceFirst(RegExp(r'^/'), '');
        final file = File(p.join(destinationPath, relativePath));
        await file.create(recursive: true);

        final data = await rootBundle.load(asset);
        await file.writeAsBytes(data.buffer.asUint8List());
      }

      return true;
    } catch (error) {
      print('Error extracting assets $error');
      return false;
    }
  }
}
