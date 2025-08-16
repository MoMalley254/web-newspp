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
}
