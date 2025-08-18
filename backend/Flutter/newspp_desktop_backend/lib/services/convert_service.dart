import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:url_launcher/url_launcher.dart';

class Pdf2HtmlConverter {
  final toastHelper = ToastService();

  /// Prepares the executable and required data folder.
  /// Returns true if successfully prepared.
  Future<Map<String, dynamic>> prepareExecutable() async {
    toastHelper.showProcessingtoast('Preparing Magazine Converter', 3);
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

      return {'status': true, 'toolDir': toolDir.path};
    } catch (e) {
      print('❌ Error preparing executable: $e');
      return {'status': false, 'error': e};
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

      final matchingAssets =
          manifestMap.keys
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

  Future<Map<String, dynamic>> convertToHtml({
    required String pdfPath,
    required String pdfName,
    required String outputDir,
  }) async {
    try {
      final toolDir = await prepareExecutable();
      (!toolDir['status']) ? throw Exception(toolDir['error']) : null;

      toastHelper.showSuccesstoast('Converter ready');
      String toolPath = toolDir['toolDir'];
      final exePath = p.join(toolDir['toolDir'], 'pdf2htmlEX.exe');
      final dataDir = p.join(toolDir['toolDir'], 'data');

      final args = ['--dest-dir', toolPath, '--data-dir', dataDir, pdfPath];

      toastHelper.showProcessingtoast(
        'Converting magazine, do not close this window',
        7,
      );
      final process = await Process.start(exePath, args, runInShell: true);

      process.stdout.transform(SystemEncoding().decoder).listen((line) {
        print('[stdout] $line');
      });

      process.stderr.transform(SystemEncoding().decoder).listen((line) {
        print('[stderr] $line');
      });

      final exitCode = await process.exitCode;
      print('✅ Conversion complete. Exit code: $exitCode');

      String htmlPath = p.join(toolPath, pdfName.replaceAll('.pdf', '.html'));
      print('HTML file path $htmlPath');
      final cleanPath = r'$htmlPath';
      print(' ');
      print('Clean HTML file path $cleanPath');
      toastHelper.showSuccesstoast('Conversion completed');
      toastHelper.showClickableSuccesstoast(
        'Conversion completed click to open converted file',
        10,
        () => openConvertedHtml(htmlPath),
      );
      return {'status': true, 'htmlPath': htmlPath};
    } catch (error) {
      print('Error converting $error');
      toastHelper.showErrortoast('Conversion error $error');
      return {'status': false, 'error': error};
    }
  }

  Future<void> openConvertedHtml(String htmlPath) async {
    try {
      final fileUri = Uri.file(htmlPath, windows: Platform.isWindows);
      print('Clean URI: $fileUri');

      if (Platform.isWindows) {
        // Open in default app (browser for .html, PDF reader for .pdf)
        await Process.run('explorer', [htmlPath]);
        print("Opened HTML via Explorer: $htmlPath");
      } else {
        // keep url_launcher for non-Windows
        final uri = Uri.file(htmlPath);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          toastHelper.showErrortoast('Unable to open HTML file: $uri');
        }
      }
    } catch (error) {
      print('Unable to open html $error');
      toastHelper.showErrortoast('Error opening html file $error');
    }
  }

  Future<void> openOnlineHtml(String htmlUrl, String magName) async {
    try {
      toastHelper.showProcessingtoast('Opening $magName please wait...', 2);

      if (Platform.isWindows) {
        // Open in default app (browser for .html, PDF reader for .pdf)
        await Process.run('explorer', [htmlUrl]);
      } else {
        // keep url_launcher for non-Windows
        final uri = Uri.file(htmlUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          toastHelper.showErrortoast('Unable to open HTML file: $uri');
        }
      }
    } catch (error) {
      print('Unable to open html $error');
      toastHelper.showErrortoast('Error opening html file $error');
    }
  }

  // Future<Map<String, dynamic>> extractTextFromHtml(String htmlFilePath) async {
  //   try {
  //     final file = File(htmlFilePath);
  //     final htmlString = await file.readAsString();

  //     // Step 2: Parse HTML
  //     final document = html_parser.parse(htmlString);
  //     final docImages = document.querySelectorAll('img');
  //     if (docImages.length < 1) {
  //       return {'status': false, 'error': 'No images found'};
  //     }
  //     print('Found ${docImages.length} images');

  //     for (var i = 0; i < docImages.length; i++) {
  //       print('Image $i: ');
  //       print('Start extract text for image $i');
  //       await getTextFromImg(docImages[i], i);
  //       print(' ');
  //       print(' ');
  //     }

  //     return {'status': true};
  //   } catch (error) {
  //     print('Error extracting parsing and extracting text $error');
  //     toastHelper.showErrortoast('Error parsing HTML $error');
  //     return {'status': false};
  //   }
  // }

  // Future<Map<String, dynamic>> getTextFromImg(
  //   Element imageElement,
  //   int index,
  // ) async {
  //   try {
  //     //Extract base64 string
  //     final regex = RegExp(r'data:image/(\w+);base64,(.*)');
  //     final imgSrc = imageElement.attributes['src'];
  //     final match = regex.firstMatch(imgSrc!);

  //     if (match == null) {
  //       print('Image $index: Failed to parse base64');
  //       throw Exception('Failed to parse image');
  //     }

  //     final imageFormat = match.group(1); // e.g. 'png', 'jpeg'
  //     final base64Data = match.group(2);

  //     if (base64Data == null) {
  //       print('Image $index: No base64 data found');
  //       throw Exception('Failed to parse image');
  //     }

  //     final bytes = base64Decode(base64Data);

  //     // Write image to temp file for ML Kit
  //     final tempDir = await getTemporaryDirectory();
  //     final tempImage = File('${tempDir.path}/temp_image.png');
  //     await tempImage.writeAsBytes(bytes);

  //     String extractedText = await performOCR(tempImage);
  //     return {'status': true};
  //   } catch (error) {
  //     print('Error extracting text from image $index, error $error');
  //     return {'status': false};
  //   }
  // }

  // Future<String> performOCR(File imageFile) async {
  //   try {
  //     // Ensure file exists
  //     if (!await imageFile.exists()) {
  //       throw Exception('Image file does not exist: ${imageFile.path}');
  //     }

  //     print('Temp image found starting OCR');
  //     final text = await TesseractOcr.extractText(imageFile.path);
  //     print('OCR successful');
  //     print('Extracted text $text');
  //     return text.trim();
  //   } catch (error) {
  //     print('error doing ocr $error');
  //     return '';
  //   }
  // }
}
