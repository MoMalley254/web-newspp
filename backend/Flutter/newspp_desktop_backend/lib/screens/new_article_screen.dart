import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:newspp_desktop_backend/widgets/forms/new_article_form.dart';

class NewArticleScreen extends StatefulWidget {
  const NewArticleScreen({super.key});

  @override
  State<NewArticleScreen> createState() => _NewArticleScreenState();
}

class _NewArticleScreenState extends State<NewArticleScreen> {
  final convertHelper = Pdf2HtmlConverter();
  final toastHelper = ToastService();
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
              child: Center(child: newArticleSide(context)),
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

  Widget newArticleSide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NewArticleForm(
        onFormValid: (formData) {
          processMagazine(formData);
        },
      ),
    );
  }

  Future<void> processMagazine(Map<String, dynamic> formData) async {
    toastHelper.showProcessingtoast('Preparing Magazine Converter', 5);
    bool prepareExe = await convertHelper.prepareExecutable();
    prepareExe
        ? toastHelper.showSuccesstoast('Converter ready')
        : toastHelper.showErrortoast(
          'Converter is not ready please retry or contact support',
        );
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
