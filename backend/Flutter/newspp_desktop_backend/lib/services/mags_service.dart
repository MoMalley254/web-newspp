import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newspp_desktop_backend/core/network/dio_client.dart';
import 'package:newspp_desktop_backend/core/network/urls.dart';
import 'package:newspp_desktop_backend/models/toc.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class MagsService {
  final Dio _dio = DioClient.instance;
  final toastHelper = ToastService();
  final convertHelper = Pdf2HtmlConverter();
  static const String baseMagUrl = '/admin/mag';

  Future<Map<String, dynamic>> getAllMags() async {
    try {
      final response = await _dio.get('$baseMagUrl/all');

      if (response.statusCode == 200) {
        List<dynamic> responseData = response.data['magazines'];

        // Iterate and update htmlPath and coverImage
        List<dynamic> updatedMags =
            responseData.map((mag) {
              // Ensure mag is a Map<String, dynamic>
              if (mag is Map<String, dynamic>) {
                mag['html'] = '$baseHost/front/view?article=${mag['id']}';
                mag['cover'] =
                    '$baseHost$baseMagUrl${(mag['coverImage'].toString().replaceAll('\\', '/'))}';
              }
              return mag;
            }).toList();

        return {'status': true, 'mags': updatedMags};
      } else {
        throw response.data['error'];
      }
    } catch (getAllMagsError) {
      print('Get all magazines error $getAllMagsError');
      toastHelper.showErrortoast(getAllMagsError.toString());
      return {'status': false, 'error': getAllMagsError.toString()};
    }
  }

  Future<bool> createMagazine(
    Map<String, dynamic> formData,
    String htmlPath,
    List<dynamic> pageImages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';
      // final htmlFile = File(htmlPath);
      // if (!htmlFile.existsSync()) {
      //   print('❌ HTML file not found at $htmlPath');
      //   toastHelper.showErrortoast('HTML file not found.');
      //   return false;
      // }

      // final fileName = p.basename(htmlPath);

      void printMapKeys(Map map) {
        for (var key in map.keys) {
          print('Form data key $key');
        }
      }

      printMapKeys(formData);

      final Map<String, dynamic> mapData = {
        ...formData,
        // 'html': await MultipartFile.fromFile(htmlPath, filename: fileName),
        'adminId': adminId,
      };

      if (formData['usePdf'] && pageImages.isNotEmpty) {
        print('📦 Preparing ${pageImages.length} images for upload...');

        // final List<MultipartFile> imageFiles = [];
        final List<MultipartFile> imageFiles = await prepareImages(
          pageImages,
          formData['usePdf'],
          formData['compress'],
        );

        // for (final img in pageImages) {
        //   print('Image $img');
        //   // final page = img['page'];
        //   // final bytes = img['bytes'] as Uint8List;
        //   // final fileName = '$page.jpg'; // or .png
        //   final page = img['file'];
        //   // final bytes = img['bytes'] as Uint8List;
        //   final fileName = img['page']; // or .png

        //   // final multipartFile = MultipartFile.fromBytes(
        //   //   bytes,
        //   //   filename: fileName,
        //   // );
        //   final multipartFile = await MultipartFile.fromFile(
        //     page.path,
        //     filename: fileName,
        //   );

        //   imageFiles.add(multipartFile);
        //   // print('📎 Attached page $page as $fileName');
        //   print('📎 Attached page $page as $fileName');
        // }

        // ✅ Attach all images under one key
        mapData['images'] = imageFiles;
      } else {
        List<File> pages = formData['images'];
        // final List<MultipartFile> imageFiles = [];
        final List<MultipartFile> imageFiles = await prepareImages(
          pages,
          formData['usePdf'],
          formData['compress'],
        );
        // if (pages.isNotEmpty) {
        //   for (final image in pages) {
        //     final imageFile = await MultipartFile.fromFile(image.path);
        //     imageFiles.add(imageFile);
        //   }
        // }
        // ✅ Attach all images under one key
        mapData['images'] = imageFiles;
      }

      final coverFile = formData['cover'] as PlatformFile?;
      if (coverFile != null && coverFile.path != null) {
        mapData['cover'] = await MultipartFile.fromFile(
          coverFile.path!,
          filename: coverFile.name,
        );
      }

      final form = FormData.fromMap(mapData);

      final response = await _dio.post('$baseMagUrl/new', data: form);

      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast(
          "${formData['title']} uploaded successfully please wait for clean up",
        );

        // ✅ Delete the HTML file after successful upload
        try {
          Map<String, dynamic> clean = await convertHelper.deleteImages(
            formData['compress'],
          );
          if (!clean['status']) {
            toastHelper.showWarningtoast(
              'Files not cleaned, please delete manually from ${clean['pagesDir']}',
            );
          }
        } catch (e) {
          print('⚠️ Failed to delete HTML file: $e');
        }

        return true;
      }
      return false;
    } catch (createMagazineError) {
      print('Create magazine error $createMagazineError');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchSingleMagazine(String magazineId) async {
    try {
      final response = await _dio.get(
        '$baseMagUrl/one',
        data: {'id': magazineId},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> magazine = Map<String, dynamic>.from(
          response.data['mag'],
        );

        magazine['html'] = '$baseHost/front/view?article=${magazine['id']}';
        magazine['cover'] =
            '$baseHost$baseMagUrl${(magazine['coverImage'].toString().replaceAll('\\', '/'))}';
        return {'status': true, 'magazine': magazine};
      } else {
        final error = response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return {'status': false, 'error': error};
      }
    } catch (fetchSingleMagazineError) {
      print('Ftech single magazine error $fetchSingleMagazineError');
      toastHelper.showErrortoast(fetchSingleMagazineError.toString());
      return {'status': false, 'error': fetchSingleMagazineError};
    }
  }

  Future<bool> processMagazine(
    PlatformFile? newPdf,
    String id,
    String name,
    String pagesPath,
  ) async {
    if (newPdf == null || newPdf.path == null) {
      toastHelper.showErrortoast('No PDF file provided.');
      return false;
    }
    toastHelper.showProcessingtoast('Preparing Magazine Converter', 5);

    Map<String, dynamic> convert = await convertHelper.convertToHtml(
      pdfPath: newPdf.path!,
      pdfName: newPdf.name,
      outputDir: 'C:/Users/user/Desktop/output',
    );

    if (!convert['status']) {
      return false;
    }

    Map<String, dynamic> mapToUpdate = {
      'id': id,
      'name': name,
      'field': 'htmlPath',
      'value': convert['images'],
      'pagesPath': pagesPath,
    };

    bool uploadToServer = await updateMagazine(mapToUpdate, true);

    // bool uploadToServer = await uploadUpdatedFileToServer({
    //   'name': 'Mag name',
    //   'field': 'htmlPath',
    //   'file': convert['htmlPath'],
    // });

    if (!uploadToServer) {
      return false;
    }

    // TODO:CONFIGURE DELETE COMPRESSED
    await convertHelper.deleteImages(true);
    return true;
  }

  Future<bool> updateMagazine(
    Map<String, dynamic> magazineData,
    hasFile,
  ) async {
    try {
      print('Magazine data b4 clean $magazineData');
      String updateUrl = '$baseMagUrl/update';
      Map<String, dynamic> queryParams = {};
      if (hasFile) {
        if (magazineData['field'] == 'htmlPath') {
          updateUrl += '/pdf';
          queryParams['pagesPath'] = magazineData['pagesPath'];
          final List<MultipartFile> imageFiles = await prepareImages(
            magazineData['value'],
            true,
            true,
          );

          print('Image files: ${imageFiles.length}');

          List<MultipartFile> finalHtmlFiles = [];

          if (imageFiles.isNotEmpty) {
            finalHtmlFiles = imageFiles;
          } else {
            // Fallback: create MultipartFile for each path in original data
            final originalPaths = magazineData['value'];

            if (originalPaths is List<String>) {
              finalHtmlFiles = await Future.wait(
                originalPaths.map((path) async {
                  return await MultipartFile.fromFile(path);
                }),
              );
            }
          }

          // Assign to the expected field as a list under a single key
          magazineData['images'] = finalHtmlFiles;
          magazineData.remove('value'); // This key seems to hold raw files
          magazineData.remove('field'); // No longer needed
        } else if (magazineData['field'] == 'coverImage') {
          magazineData['cover'] = await MultipartFile.fromFile(
            magazineData['value'],
            // filename: magazineData['field'].name,
          );
        }
      }

      print('Magazine after clean $magazineData');

      final update = FormData.fromMap(magazineData);

      final response = await _dio.post(
        updateUrl,
        queryParameters: queryParams,
        data: update,
      );

      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast(
          '${magazineData['name']}, updated successfully',
        );
        return true;
      } else {
        final error = await response.data['error'];
        print('Error updating $error');
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (updateMagazineError) {
      print('Update magazine error $updateMagazineError');
      toastHelper.showErrortoast(updateMagazineError.toString());
      return false;
    }
  }

  Future<bool> deleteMagazine(String magId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';

      final response = await _dio.post(
        '$baseMagUrl/del',
        data: {'magId': magId, 'admin': adminId},
      );
      if (response.statusCode == 200) {
        toastHelper.showSuccesstoast('Magazine deleted successfully');
        return true;
      }

      final error = await response.data['error'];
      print('Error deleting $error');
      toastHelper.showErrortoast(error.toString());
      return false;
    } catch (deleteMagazineError) {
      print('Delete magazine error $deleteMagazineError');
      toastHelper.showErrortoast(deleteMagazineError.toString());
      return false;
    }
  }

  Future<List<MultipartFile>> prepareImages(
    List<dynamic> images,
    bool usePdfFile,
    bool compress,
  ) async {
    try {
      print('Should compress $compress');
      final List<MultipartFile> multipartImages = [];

      // Step 2: Compress images if needed
      if (compress) {
        // Step 1: Extract image paths
        final List<String> imagePaths =
            images
                .map((image) {
                  if (usePdfFile) {
                    final file = image['file'];
                    if (file is File) {
                      return file.path;
                    } else {
                      print('WARN: Unexpected file type: ${file.runtimeType}');
                      return null;
                    }
                  } else {
                    return image.path;
                  }
                })
                .whereType<String>()
                .toList();

        final List<dynamic> compressedImages = await convertHelper
            .compressImages(imagePaths);

        if (compressedImages.isNotEmpty) {
          for (final img in compressedImages) {
            final file = img['file'];
            if (file is File) {
              final imageFile = await MultipartFile.fromFile(file.path);
              multipartImages.add(imageFile);
            }
          }
        } else {
          // Compression failed — fall back to original images
          return await _fallbackMultipartImages(images, usePdfFile);
        }
      } else {
        // No compression — use original images
        return await _fallbackMultipartImages(images, usePdfFile);
      }

      return multipartImages;
    } catch (e) {
      print('Prepare images error $e');
      toastHelper.showErrortoast(e.toString());
      return [];
    }
  }

  Future<List<MultipartFile>> _fallbackMultipartImages(
    List<dynamic> images,
    bool usePdfFile,
  ) async {
    print('Fallback to no compress');
    final List<MultipartFile> result = [];

    for (final image in images) {
      if (usePdfFile) {
        // image is File
        final imageFile = await MultipartFile.fromFile(image['file'].path);
        result.add(imageFile);
      } else {
        // image is Map with 'file' and 'page'
        print('Image $image');
        final multipartFile = await MultipartFile.fromFile(image.path);
        result.add(multipartFile);
      }
    }

    print('Result $result');

    return result;
  }

  Future<bool> addTocs(String magId, List<Map<String, dynamic>> tocs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';

      final response = await _dio.post(
        '$baseMagUrl/toc/new',
        data: {'admin': adminId, 'mag': magId, 'tocs': tocs},
      );

      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast('Table of contents updated');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (addTocsError) {
      toastHelper.showErrortoast(addTocsError.toString());
      return false;
    }
  }

  Future<bool> removeTocs(String magId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';

      final response = await _dio.post(
        '$baseMagUrl/toc/destroy',
        data: {'admin': adminId, 'mag': magId},
      );

      if (response.statusCode == 203) {
        toastHelper.showSuccesstoast('Table of contents deleted');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (removeTocsError) {
      toastHelper.showErrortoast(removeTocsError.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> getTocs(String magId) async {
    try {
      final response = await _dio.get('$baseMagUrl/toc/get?mag=$magId');

      if (response.statusCode == 200) {
        final tocs = await response.data['tocs'];
        return {'status': true, 'tocs': tocs};
      } else {
        final error = await response.data['error'];
        return {'status': false, 'error': error};
      }
    } catch (getTocsError) {
      toastHelper.showErrortoast(getTocsError.toString());
      return {'status': false, 'error': getTocsError.toString()};
    }
  }

  Future<bool> editSingleToc(String tocId, String field, String value) async {
    toastHelper.showProcessingtoast('Updating please wait...', 7);
    try {
      final response = await _dio.post(
        '$baseMagUrl/toc/edit',
        data: {'tocId': tocId, 'field': field, 'value': value},
      );

      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast('$field updated to $value');
        return true;
      } else {
        final error = await response.data["error"];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (editSingleTocError) {
      toastHelper.showErrortoast(editSingleTocError.toString());
      return false;
    }
  }

  Future<bool> deleteOneToc(String tocId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';

      final response = await _dio.post(
        '$baseMagUrl/toc/del',
        data: {'toc': tocId},
      );

      if (response.statusCode == 203) {
        toastHelper.showSuccesstoast('Entry deleted');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (deleteOneTocError) {
      toastHelper.showErrortoast(deleteOneTocError.toString());
      return false;
    }
  }

  Future<bool> deleteOneLink(String link, String magId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';

      final response = await _dio.post(
        '$baseMagUrl/link/del',
        data: {'link': link, 'magId': magId},
      );

      if (response.statusCode == 203) {
        toastHelper.showSuccesstoast('Link deleted');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (deleteOneLinkError) {
      toastHelper.showErrortoast(deleteOneLinkError.toString());
      return false;
    }
  }
}
