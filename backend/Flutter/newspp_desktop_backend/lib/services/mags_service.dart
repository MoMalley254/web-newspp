import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newspp_desktop_backend/core/network/dio_client.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class MagsService {
  final Dio _dio = DioClient.instance;
  final toastHelper = ToastService();
  static const String baseMagUrl = '/admin/mag';

  Future<Map<String, dynamic>> getAllMags() async {
  try {
    final response = await _dio.get('$baseMagUrl/all');

    if (response.statusCode == 200) {
      List<dynamic> responseData = response.data['magazines'];

      // Iterate and update htmlPath and coverImage
      List<dynamic> updatedMags = responseData.map((mag) {
        // Ensure mag is a Map<String, dynamic>
        if (mag is Map<String, dynamic>) {
          mag['html'] = 'http://localhost:3000${baseMagUrl}${(mag['htmlPath'].toString().replaceAll('\\', '/'))}';
          mag['cover'] = 'http://localhost:3000${baseMagUrl}${(mag['coverImage'].toString().replaceAll('\\', '/') ?? '')}';
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
}
