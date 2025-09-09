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
    print('Admin data $adminData');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminId', adminData['id']);
      await prefs.setString('adminEmail', adminData['email']);
      await prefs.setString('adminName', adminData['name']);
      await prefs.setString('adminRole', adminData['role']);

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
      String? adminRole = await prefs.getString('adminRole');

      if (adminId == null || adminEmail == null || adminName == null) {
        return {'status': false, 'error': 'Missing fields please login again'};
      }

      return {
        'status': true,
        'name': adminName,
        'email': adminEmail,
        'id': adminId,
        'role': adminRole,
      };
    } catch (getAdminDataError) {
      print('Get admin data error $getAdminDataError');
      toastHelper.showErrortoast(getAdminDataError.toString());
      return {'status': false, 'error': getAdminDataError.toString()};
    }
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] || adminData['id'] == '') {
        return false;
      }
      final response = await _dio.post(
        '/admin/update',
        data: {
          'admin': adminData['id'],
          'oldPass': oldPass,
          'newPass': newPass,
        },
      );
      if (response.statusCode == 201) {
        //Force login
        await logout();
        toastHelper.showSuccesstoast(
          'Changed password successfully please wait for redirect...',
        );
        return true;
      } else {
        print('Error ${response.data}');
        throw response.data['error'];
      }
    } catch (changePasswordError) {
      toastHelper.showErrortoast(changePasswordError.toString());
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (logoutError) {
      toastHelper.showErrortoast(logoutError.toString());
      return false;
    }
  }

  Future<bool> createNewAdmin(Map<String, dynamic> newAdminData) async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] ||
          adminData['id'] == '' ||
          adminData['role'] != 'ADMIN') {
        toastHelper.showWarningtoast('Unauthorized');
        return false;
      }

      final response = await _dio.post(
        '/admin/create',
        data: {...newAdminData, 'creator': adminData['id']},
      );
      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast('User created');
        return true;
      } else {
        print('Error ${response.data}');
        throw response.data['error'];
      }
    } catch (createNewAdminError) {
      toastHelper.showErrortoast(createNewAdminError.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdmins() async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] ||
          adminData['id'] == '' ||
          adminData['role'] != 'ADMIN') {
        toastHelper.showWarningtoast('Unauthorized');
        return {'status': false, 'error': 'Not authorized'};
      }
      final response = await _dio.post(
        '/admin/all',
        data: {'admin': adminData['id']},
      );
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> filteredAdmins =
            List<Map<String, dynamic>>.from(
              (response.data['admins'] ?? []).where(
                (admin) => admin['id'] != adminData['id'],
              ),
            );

        return {'status': true, 'admins': filteredAdmins};
      } else {
        final error = await response.data['error'];
        return {'status': false, 'error': error ?? 'Server error'};
      }
    } catch (getAdminsError) {
      toastHelper.showErrortoast(getAdminsError.toString());
      return {'status': false, 'error': getAdminsError.toString()};
    }
  }

  Future<bool> updateAccount(
    String accountId,
    String field,
    String value,
  ) async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] ||
          adminData['id'] == '' ||
          adminData['role'] != 'ADMIN') {
        toastHelper.showWarningtoast('Unauthorized');
        return false;
      }
      final response = await _dio.post(
        '/admin/change',
        data: {
          'admin': adminData['id'],
          'account': accountId,
          'field': field,
          'value': value,
        },
      );

      if (response.statusCode == 201) {
        toastHelper.showSuccesstoast('Account updated');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (updateAccountError) {
      toastHelper.showErrortoast(updateAccountError.toString());
      return false;
    }
  }

  Future<bool> deleteAcount(String accountId) async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] ||
          adminData['id'] == '' ||
          adminData['role'] != 'ADMIN') {
        toastHelper.showWarningtoast('Unauthorized');
        return false;
      }

      if (adminData['id'] == accountId) {
        toastHelper.showWarningtoast('Cannot delete logged in account');
        return false;
      }
      final response = await _dio.post(
        '/admin/destroy',
        data: {'admin': adminData['id'], 'account': accountId},
      );

      if (response.statusCode == 203) {
        toastHelper.showSuccesstoast('Account deleted');
        return true;
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast(error.toString());
        return false;
      }
    } catch (deleteAccountError) {
      toastHelper.showErrortoast(deleteAccountError.toString());
      return false;
    }
  }

  Future<bool> logoutAdmin() async {
    try {
      Map<String, dynamic> adminData = await getAdminData();
      if (!adminData['status'] || adminData['id'] == '') {
        toastHelper.showWarningtoast('No Account');
        return false;
      }

      String aToken = await DioClient().getAToken();
      String rToken = await DioClient().getRToken();

      if (aToken.isEmpty || rToken.isEmpty) {
        //Force login
        return true;
      }

      final response = await _dio.post(
        '/admin/logout',
        data: {
          'admin': adminData['id'],
          'aToken': aToken,
          'rToken': rToken
        },
      );

      if (response.statusCode == 203) {
        bool deletePrefs = await logout();
        if (deletePrefs) {
          toastHelper.showSuccesstoast(
            'Logged out successfully please wait for clean up...',
          );
          return true;
        } else {
          return false;
        }
      } else {
        final error = await response.data['error'];
        toastHelper.showErrortoast('$error');
        return false;
      }
    } catch (logoutError) {
      toastHelper.showErrortoast(logoutError.toString());
      return false;
    }
  }
}
