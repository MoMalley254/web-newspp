import 'package:dio/dio.dart';
import 'package:newspp_desktop_backend/core/network/dio_client.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:newspp_desktop_backend/services/tokens_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = DioClient.instance;
  final toastHelper = ToastService();
  final tokensHelper = TokenStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/admin/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = {...response.data['admin']};

        bool saveTokens = await saveAdminTokens(
          responseData['aToken'],
          responseData['rToken'],
        );

        if (!saveTokens) return false;

        bool savePrefs = await saveAdminData(responseData);
        if (!savePrefs) return false;

        toastHelper.showSuccesstoast(
          'Login successful please wait for redirect...',
        );
        return true;
      } else {
        print('Error ${response.data}');
        throw response.data['error'];
      }
    } catch (loginError) {
      toastHelper.showErrortoast('$loginError');
      return false;
    }
  }

  Future<bool> saveAdminData(Map<String, dynamic> adminData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminId', adminData['id']);
      await prefs.setString('adminEmail', adminData['email']);
      await prefs.setString('adminName', adminData['name']);

      await prefs.setBool('loggedIn', true);

      return true;
    } catch (saveAdminDataError) {
      print('Error saving admin data $saveAdminDataError');
      toastHelper.showErrortoast(saveAdminDataError.toString());
      return false;
    }
  }

  Future<bool> saveAdminTokens(String aToken, String rToken) async {
    try {
      await tokensHelper.saveTokens(aToken, rToken);
      return true;
    } catch (saveTokensError) {
      print('Save tokens error $saveTokensError');
      toastHelper.showErrortoast(saveTokensError.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? adminId = await prefs.getString('adminId');
      String? adminEmail = await prefs.getString('adminEmail');
      String? adminName = await prefs.getString('adminName');

      if (adminId == null || adminEmail == null || adminName == null) {
        return {'status': false, 'error': 'Missing fields please login again'};
      }

      return {
        'status': true,
        'name': adminName,
        'email': adminEmail,
        'id': adminId,
      };
    } catch (getAdminDataError) {
      print('Get admin data error $getAdminDataError');
      return {'status': false, 'error': getAdminDataError.toString()};
    }
  }
}
