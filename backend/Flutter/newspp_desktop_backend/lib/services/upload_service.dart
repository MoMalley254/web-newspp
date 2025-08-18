import 'package:newspp_desktop_backend/services/toast_service.dart';

class UploadService {
  final toastHelper = ToastService();

  Future<bool> sendMagDataToServer(Map<String, dynamic> magData) async {
    try {
      toastHelper.showSuccesstoast('Magazine Uploaded successfuly');
      return true;
    } catch (error) {
      print('Error sending mag data to server $error');
      toastHelper.showErrortoast('Error uploading magazine $error');
      return false;
    }
  }

  Future<bool> sendUpdateToServer(Map<String, dynamic> updatedData) async {
    try {
      toastHelper.showProcessingtoast(
        'Updating ${updatedData['name']} please wait...',
        3,
      );
      await Future.delayed(const Duration(seconds: 5));
      toastHelper.showSuccesstoast('Updated ${updatedData['name']}');
      return true;
    } catch (error) {
      print('Error updating ${updatedData['name']}, error $error');
      toastHelper.showErrortoast(
        'Error updating ${updatedData['name']}, Error $error',
      );
      return false;
    }
  }
}
