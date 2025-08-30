import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
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
    try {
      final supportDir = await getApplicationSupportDirectory();
      // final toolDir = Directory(p.join(supportDir.path, 'pdf2htmlEX'));
      final toolDir = Directory(p.join(supportDir.path, 'pdf2images'));

      print('📁 Support directory: ${supportDir.path}');
      print('🔧 Tool directory: ${toolDir.path}');

      // final exePath = p.join(toolDir.path, 'pdf2htmlEX.exe');
      final exePath = p.join(toolDir.path, 'convert.exe');
      // final dataDirPath = p.join(toolDir.path, 'data');
      final popplerBinPath = p.join(toolDir.path, 'poppler', 'bin');
      final popplerDir = Directory(popplerBinPath);

      final exeFile = File(exePath);

      if (!await exeFile.exists() || !await popplerDir.exists()) {
        // print('⚙️ Extracting pdf2htmlEX.exe and data/ folder...');
        print('⚙️ Extracting convert.exe...');

        await toolDir.create(recursive: true);

        // Extract the .exe
        // final exeBytes = await rootBundle.load(
        //   'assets/bin/windows/pdf2htmlex/pdf2htmlEX.exe',
        // );
        final exeBytes = await rootBundle.load(
          'assets/bin/windows/convert.exe',
        );
        await exeFile.writeAsBytes(exeBytes.buffer.asUint8List());

        // Extract the data directory
        // final success = await _extractAssetFolder(
        //   assetPath: 'assets/bin/windows/pdf2htmlex/data/',
        //   destinationPath: dataDirPath,
        // );

        // if (!success) {
        //   throw Exception('❌ Failed to extract asset folder');
        // }
        final success = await _extractAssetFolder(
          assetPath: 'assets/bin/windows/poppler/bin/',
          destinationPath: popplerBinPath,
        );

        if (!success) {
          throw Exception('❌ Failed to extract asset folder');
        }

        // print('✅ Assets extracted to $dataDirPath');
        print('✅ Assets extracted to $popplerBinPath');
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
      // final exePath = p.join(toolDir['toolDir'], 'pdf2htmlEX.exe');
      final exePath = p.join(toolDir['toolDir'], 'convert.exe');
      // final dataDir = p.join(toolDir['toolDir'], 'data');
      final popplerDir = p.join(toolDir['toolDir'], 'poppler', 'bin');

      final pagesDir = p.join(toolDir['toolDir'], 'pages');
      final outputDirExists = await Directory(pagesDir).exists();
      if (!outputDirExists) {
        await Directory(pagesDir).create(recursive: true);
        print('📁 Created output directory: $pagesDir');
      } else {
        print('📁 Output directory already exists: $pagesDir');
      }

      // final args = ['--dest-dir', toolPath, '--data-dir', dataDir, pdfPath];
      // final args = [
      //   '--split-pages', '1', // ✅ This is the key flag
      //   '--dest-dir', pagesDir, // where to output the files
      //   '--data-dir', dataDir, // required data folder
      //   pdfPath, // input PDF file
      // ];

      toastHelper.showProcessingtoast(
        'Processing magazine, do not close this window',
        7,
      );
      // final process = await Process.start(exePath, args, runInShell: true);
      final process = await Process.start(exePath, [
        pdfPath,
        popplerDir,
        pagesDir,
      ], runInShell: true);

      // Listen to stdout
      process.stdout.transform(SystemEncoding().decoder).listen((line) {
        print("LOG: $line"); // You can send this to the UI
        toastHelper.showProcessingtoast(line, 3);
      });

      // Listen to stderr
      process.stderr.transform(SystemEncoding().decoder).listen((line) {
        print("LOG: $line");
        toastHelper.showWarningtoast(line);
      });

      // process.stdout.transform(SystemEncoding().decoder).listen((line) {
      //   print('[stdout] $line');

      //   if (line.contains('Preprocessing')) {
      //     toastHelper.showProcessingtoast('Loading PDF pages...', 3);
      //   } else if (line.contains('Working')) {
      //     final match = RegExp(r'Working:  (\d+)').firstMatch(line);
      //     if (match != null) {
      //       toastHelper.showProcessingtoast(
      //         'Processing page ${match.group(1)}',
      //         3,
      //       );
      //     }
      //   }
      // });

      // process.stderr.transform(SystemEncoding().decoder).listen((line) {
      //   print('[stderr] $line');
      //   toastHelper.showWarningtoast('PDF warning: $line');
      // });

      final exitCode = await process.exitCode;
      if (exitCode == 1) {
        return {'status': false, 'error': 'Conversion failed'};
      }
      print('✅ Conversion complete. Exit code: $exitCode');

      // String htmlPath = p.join(toolPath, pdfName.replaceAll('.pdf', '.html'));
      // print('HTML file path $htmlPath');
      // final cleanPath = r'$htmlPath';
      // print(' ');
      // print('Clean HTML file path $cleanPath');
      toastHelper.showSuccesstoast('Conversion completed, please wait');

      Map<String, dynamic> getImages = await getImagesFromFiles(pagesDir);
      if (!getImages['status']) {
        return {'status': false, 'error': getImages['error']};
      }

      // return {'status': true, 'htmlPath': htmlPath};
      return {
        'status': true,
        'outputDir': pagesDir,
        'images': getImages['images'],
      };
    } catch (error) {
      print('Error converting $error');
      toastHelper.showErrortoast('Conversion error $error');
      return {'status': false, 'error': error};
    }
  }

  Future<Map<String, dynamic>> getImagesFromFiles(String pagesDir) async {
    toastHelper.showProcessingtoast('Extracting data please wait...', 5);
    try {
      final dir = Directory(pagesDir);

      if (!await dir.exists()) {
        throw Exception('Directory does not exist: $pagesDir');
      }

      final allFiles = dir.listSync();
      // final pageFiles =
      //     allFiles
      //         .where(
      //           (f) =>
      //               f is File && p.extension(f.path).toLowerCase() == '.page',
      //         )
      //         .toList();
      final pageFiles =
          allFiles
              .where(
                (f) => f is File && p.extension(f.path).toLowerCase() == '.png',
              )
              .toList();

      print('📄 Total files found: ${allFiles.length}');
      print('📄 .page files found: ${pageFiles.length}');

      List<Map<String, dynamic>> images = [];

      for (final file in pageFiles) {
        final filePath = file.path;
        print('🔍 Processing file: $filePath');

        final fileName = p.basename(filePath);
        final imageFile = File(filePath);
        // final match = RegExp(r'(\d+)$').firstMatch(fileName);
        // if (match == null) {
        //   print('⚠️ Skipping: Cannot extract page number from $fileName');
        //   continue;
        // }

        // final pageNumber = int.parse(match.group(1)!);

        // final content = await File(filePath).readAsString();
        // final document = parse(content);
        // final imgTags = document.getElementsByTagName('img');

        // if (imgTags.isEmpty) {
        //   print('⚠️ No <img> tags found in $filePath');
        //   continue;
        // }

        // final img = imgTags.first;
        // final src = img.attributes['src'];

        // if (src == null || !src.startsWith('data:image/')) {
        //   print('⚠️ No valid base64 image found in $filePath');
        //   continue;
        // }

        try {
          // final base64Str = src.split(',')[1];
          // final imageBytes = base64.decode(base64Str);

          // images.add({'page': pageNumber, 'bytes': imageBytes});
          images.add({'page': fileName, 'file': imageFile});

          print('🖼️ Extracted image for page ${file.path}');
        } catch (err) {
          print('❌ Failed to decode image in $filePath: $err');
        }
      }

      return {
        'status': true,
        'images': images, // List of { page, bytes }
      };
    } catch (getImagesFromFilesError) {
      print('❌ Get images from files error: $getImagesFromFilesError');
      toastHelper.showErrortoast(getImagesFromFilesError.toString());
      return {'status': false, 'error': getImagesFromFilesError.toString()};
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

  Future<Map<String, dynamic>> deleteImages() async {
    String pagesDir = '';
    try {
      toastHelper.showProcessingtoast('Cleaning up files, please wait...', 3);

      final supportDir = await getApplicationSupportDirectory();
      final toolDir = Directory(p.join(supportDir.path, 'pdf2images'));
      if (!toolDir.existsSync()) {
        throw Exception('File system not found');
      }

      pagesDir = p.join(toolDir.path, 'pages');
      final directory = Directory(pagesDir);

      // Check if the directory exists
      if (await directory.exists()) {
        final files = directory.listSync();

        // Loop through each file and delete if it's an image
        for (var file in files) {
          if (file is File && _isImage(file.path)) {
            try {
              await file.delete();
              print('Deleted image: ${file.path}');
            } catch (e) {
              print('Error deleting file ${file.path}: $e');
            }
          }
        }
      }

      toastHelper.showSuccesstoast('Images deleted successfully');
      return {'status': true};
    } catch (deleteImagesErr) {
      print('Delete images error: $deleteImagesErr');
      toastHelper.showErrortoast(deleteImagesErr.toString());
      return {'status': false, 'pagesDir': pagesDir};
    }
  }

  bool _isImage(String filePath) {
    // Simple check for common image file extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }
}
