import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

class NewArticleForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onFormValid;
  const NewArticleForm({super.key, required this.onFormValid});

  @override
  State<NewArticleForm> createState() => _NewArticleFormState();
}

class _NewArticleFormState extends State<NewArticleForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _issueNoController = TextEditingController();
  final _publishDateController = TextEditingController();
  final _authorController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descController = TextEditingController();

  PlatformFile? _pdfFile;
  PlatformFile? _coverImage;

  @override
  void dispose() {
    _titleController.dispose();
    _issueNoController.dispose();
    _publishDateController.dispose();
    _tagsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              '📰 Upload New Magazine',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Tech Trends – August 2025',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Title is required'
                          : null,
            ),
            const SizedBox(height: 16),

            //Author
            const Text('Author'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                hintText: 'e.g., John Doe',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Author is required'
                          : null,
            ),
            const SizedBox(height: 16),

            // Issue Number
            const Text('Issue Number'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _issueNoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 42',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Issue number is required';
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Publish Date
            const Text('Publish Date'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _publishDateController,
              decoration: InputDecoration(
                hintText: 'e.g., 2025-08-14',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Publish date is required';
                try {
                  DateTime.parse(value);
                } catch (_) {
                  return 'Invalid date format (use YYYY-MM-DD)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags / Category'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'e.g., Technology, AI, Startups',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter at least one tag'
                          : null,
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description / Summary'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Brief summary of the magazine issue...',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.length < 10
                          ? 'Description too short'
                          : null,
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Upload PDF
                Column(
                  children: [
                    const Text('PDF *Max 50MB'),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _pdfFile != null
                            ? 'PDF Selected'
                            : 'Pick PDF ',
                            overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                        if (result != null) {
                          final file = result.files.first;
                          if (file.size > 50 * 1024 * 1024) {
                            toastification.show(
                              title: Text(
                                'PDF exceeds 50MB limit. Please choose a smaller file.',
                              ),
                              type: ToastificationType.warning,
                              style: ToastificationStyle.flatColored,
                              autoCloseDuration: const Duration(seconds: 5),
                            );
                            return;
                          }
                          setState(() => _pdfFile = file);
                        }
                      },
                    ),
                  ],
                ),

                Column(
                  children: [
                    // Upload Cover Image
                    const Text('Cover Image *Max 5MB'),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                        _coverImage != null
                            ? 'Image: ${_coverImage!.name}'
                            : 'Pick Cover Image',
                      ),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null) {
                          final file = result.files.first;
                          if (file.size > 5 * 1024 * 1024) {
                            toastification.show(
                              title: Text(
                                'Image exceeds 5MB limit. Please choose a smaller image.',
                              ),
                              type: ToastificationType.warning,
                              style: ToastificationStyle.flatColored,
                              autoCloseDuration: const Duration(seconds: 5),
                            );
                            return;
                          }
                          setState(() => _coverImage = file);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Submit Magazine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_pdfFile == null) {
                    toastification.show(
                      title: Text('Please provide a PDF file of the magazine.'),
                      type: ToastificationType.warning,
                      style: ToastificationStyle.flatColored,
                      autoCloseDuration: const Duration(seconds: 5),
                    );
                    ;
                    return;
                  }

                  // Form is valid and files are selected
                  toastification.show(
                    title: Text('Submitted successfully.'),
                    type: ToastificationType.success,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 5),
                  );

                  Map<String, dynamic> formData = {
                    'title': _titleController.text,
                    'author': _authorController.text,
                    'issue': _issueNoController.text,
                    'date': _publishDateController.text,
                    'tags': _tagsController.text,
                    'desc': _descController.text,
                    'pdf': _pdfFile,
                    'cover': _coverImage,
                  };

                  widget.onFormValid(formData);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
