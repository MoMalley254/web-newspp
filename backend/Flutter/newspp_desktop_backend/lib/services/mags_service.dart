import 'package:dio/dio.dart';
import 'package:newspp_desktop_backend/core/network/dio_client.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';

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
}
