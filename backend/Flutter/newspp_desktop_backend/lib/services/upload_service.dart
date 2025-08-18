import 'package:file_picker/file_picker.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';

class UploadService {
  final toastHelper = ToastService();
  final convertHelper = Pdf2HtmlConverter();

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

  Future<bool> processMagazine(PlatformFile? newPdf) async {
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

    bool uploadToServer = await uploadUpdatedFileToServer({
      'name': 'Mag name',
      'field': 'Magazine File',
      'file': convert['htmlPath'],
    });

    if (!uploadToServer) {
      return false;
    }

    return true;
  }

  Future<bool> uploadUpdatedFileToServer(Map<String, dynamic> newData) async {
    try {
      toastHelper.showProcessingtoast(
        'Updating ${newData['name']} please wait...',
        5,
      );
      await Future.delayed(Duration(seconds: 6));
      return true;
    } catch (error) {
      print('Error uploading updated file $error');
      toastHelper.showErrortoast(
        'Error uploading ${newData['field']}, Error $error',
      );
      return false;
    }
  }
}
