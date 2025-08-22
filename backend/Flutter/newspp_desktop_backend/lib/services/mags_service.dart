import 'dart:io';

import 'package:dio/dio.dart';
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

        // print('Response $responseData');
        return {'status': true, 'mags': responseData};
      } else {
        // print('Error fr ${response.data}');
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
      String adminId = await prefs.getString('adminId') ?? '';
      final htmlFile = File(htmlPath);
      if (!htmlFile.existsSync()) {
        print('❌ HTML file not found at $htmlPath');
        toastHelper.showErrortoast('HTML file not found.');
        return false;
      }

      final fileName = p.basename(htmlPath);

      final form = FormData.fromMap({
        ...formData,
        'html': await MultipartFile.fromFile(htmlPath, filename: fileName),
        'adminId': adminId,
      });

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
      return true;
    } catch (createMagazineError) {
      print('Create magazine error $createMagazineError');
      return false;
    }
  }
}
