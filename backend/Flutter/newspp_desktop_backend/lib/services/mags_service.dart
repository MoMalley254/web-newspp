import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newspp_desktop_backend/core/network/dio_client.dart';
import 'package:newspp_desktop_backend/core/network/urls.dart';
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
                mag['html'] =
                    'http://localhost:3000${baseMagUrl}${(mag['htmlPath'].toString().replaceAll('\\', '/'))}';
                mag['cover'] =
                    'http://localhost:3000${baseMagUrl}${(mag['coverImage'].toString().replaceAll('\\', '/') ?? '')}';
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
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String adminId = prefs.getString('adminId') ?? '';
      final htmlFile = File(htmlPath);
      if (!htmlFile.existsSync()) {
        print('❌ HTML file not found at $htmlPath');
        toastHelper.showErrortoast('HTML file not found.');
        return false;
      }

      final fileName = p.basename(htmlPath);

      final Map<String, dynamic> mapData = {
        ...formData,
        'html': await MultipartFile.fromFile(htmlPath, filename: fileName),
        'adminId': adminId,
      };

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
          htmlFile.deleteSync();
          print('🗑️ Deleted local HTML file at $htmlPath');
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

        print('Mag found $magazine');
        magazine['cover'] =
            '$baseHost$baseMagUrl/public/${magazine['coverImage']}';
        magazine['html'] = '$baseHost$baseMagUrl/public/${magazine['htmlPath']}';
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

  Future<bool> processMagazine(PlatformFile? newPdf, String id, String name) async {
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
      'value': convert['htmlPath'],
    };

    bool uploadToServer = await updateMagazine(
      mapToUpdate,
      true,
    );

    // bool uploadToServer = await uploadUpdatedFileToServer({
    //   'name': 'Mag name',
    //   'field': 'htmlPath',
    //   'file': convert['htmlPath'],
    // });

    if (!uploadToServer) {
      return false;
    }

    return true;
  }

  Future<bool> updateMagazine(
    Map<String, dynamic> magazineData,
    hasFile,
  ) async {
    try {
      if (hasFile) {
        if (magazineData['field'] == 'htmlPath') {
          magazineData['html'] = await MultipartFile.fromFile(
            magazineData['value'],
          );
        } else if (magazineData['field'] == 'coverImage') {
          magazineData['cover'] = await MultipartFile.fromFile(
            magazineData['value'],
            // filename: magazineData['field'].name,
          );
        }
      }

      final update = FormData.fromMap(magazineData);

      final response = await _dio.post('$baseMagUrl/update', data: update);
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
}
