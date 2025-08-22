import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/mags_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:newspp_desktop_backend/services/upload_service.dart';
import 'package:newspp_desktop_backend/widgets/forms/new_article_form.dart';
import 'package:url_launcher/url_launcher.dart';

class NewArticleScreen extends StatefulWidget {
  final Function(String) navigateTo;
  const NewArticleScreen({super.key, required this.navigateTo});

  @override
  State<NewArticleScreen> createState() => _NewArticleScreenState();
}

class _NewArticleScreenState extends State<NewArticleScreen> {
  final convertHelper = Pdf2HtmlConverter();
  final toastHelper = ToastService();
  final uploadHelper = UploadService();
  final magsHelper = MagsService();

  bool isProcessing = false;
  bool formDataConfirmed = false;

  Map<String, dynamic>? submittedFormData;
  String processedHtmlPath = '';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left section - 60%
            Container(
              width: totalWidth * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8F8F8),
              ),
              child: Center(child: renderLeftContent(context)),
            ),

            // Right section - 20%
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8F8F8),
              ),
              width: totalWidth * 0.35,
              padding: const EdgeInsets.all(10),
              // color: Colors.red,
              child: Center(child: createHelpSide(context)),
            ),
          ],
        );
      },
    );
  }

  Widget renderLeftContent(BuildContext context) {
    if (isProcessing) {
      return const CircularProgressIndicator();
    } else if (formDataConfirmed) {
      return showReadyToUpload(context);
    } else {
      return newArticleSide(context);
    }
  }

  Widget newArticleSide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NewArticleForm(
        onFormValid: (formData) {
          setState(() {
            isProcessing = true;
            submittedFormData = formData;
          });
          processMagazine(formData);
        },
      ),
    );
  }

  Future<void> processMagazine(Map<String, dynamic> formData) async {
    toastHelper.showProcessingtoast('Preparing Magazine Converter', 5);

    Map<String, dynamic> prepareExe = await convertHelper.convertToHtml(
      pdfPath: formData['pdf'].path,
      pdfName: formData['pdf'].name,
      outputDir: 'C:/Users/user/Desktop/output',
    );

    if (!prepareExe['status']) {
      setState(() {
        isProcessing = false;
      });
      return;
    }

    setState(() {
      processedHtmlPath = prepareExe['htmlPath'];
      isProcessing = false;
      formDataConfirmed = true;
    });
  }

  Widget showReadyToUpload(BuildContext context) {
    final data = submittedFormData!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Confirm Magazine Details',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text('Title: ${data['title']}'),
          Text('Author: ${data['author']}'),
          Text('Issue: ${data['issue']}'),
          Text('Date: ${data['date']}'),
          Text('Tags: ${data['tags']}'),
          SizedBox(
  height: 200, // set the height you want for the scroll box
  child: SingleChildScrollView(
    child: Text('Description: ${data['desc']}'),
  ),
),

          const SizedBox(height: 16),
          Text('PDF: ${data['pdf'].name}'),
          if (data['cover'] != null) Text('Cover Image: ${data['cover'].name}'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text("Open Generated HTML"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await convertHelper.openConvertedHtml(processedHtmlPath);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Re-enter data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isProcessing = false;
                formDataConfirmed = false;
                submittedFormData = null;
                processedHtmlPath = '';
              });
            },
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text("Confirm & Upload"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isProcessing = true;
              });
              sendToServer(data);
            },
          ),
        ],
      ),
    );
  }

  Future<void> sendToServer(Map<String, dynamic> magazineData) async {
    // bool hasSentToServer = await uploadHelper.sendMagDataToServer(magazineData);
    bool hasSentToServer = await magsHelper.createMagazine(
      magazineData,
      processedHtmlPath,
    );
    if (hasSentToServer) {
      widget.navigateTo('Dashboard');
    }
    setState(() {
      isProcessing = false;
    });
  }

  Widget createHelpSide(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛠 Upload Guidelines',
            style: GoogleFonts.poppins(
              // color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '1. Magazine File',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '• Upload a PDF version of the magazine.\n'
            '• Maximum file size: 50MB.\n'
            '• Larger PDF files take longer to process.\n'
            '• Avoid scanned/image-only PDFs (they cannot be parsed).\n'
            '• Ensure fonts are embedded or use standard fonts.',
          ),
          const SizedBox(height: 16),

          Text(
            '2. Metadata & Info',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '• Magazine Title (e.g., "Tech Trends – August 2025")\n'
            '• Issue Number and Publish Date\n'
            '• Author or Editor name\n'
            '• Category/Tags (e.g., Technology, Lifestyle)\n'
            '• Description/Summary (used for previews and SEO) \n'
            '• Cover image (used for previews however this is optional)',
          ),
          const SizedBox(height: 16),

          Text(
            '3. Conversion Tips',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '• Make sure the PDF is properly structured for conversion.\n'
            '• Use actual text (not flattened images).\n'
            '• Headers and paragraphs should be recognizable by parsers. \n',
          ),
          const SizedBox(height: 16),

          Text(
            '4. Common Mistakes to Avoid',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '• Uploading image-only PDFs with no selectable text.\n'
            '• Skipping metadata fields.\n'
            '• Using blurry or low-res cover images.\n'
            '• Overusing custom fonts or layouts that break conversion.',
          ),
        ],
      ),
    );
  }
}
