import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/fetch_service.dart';
import 'package:newspp_desktop_backend/services/upload_service.dart';
import 'package:toastification/toastification.dart';

class ArticleInfo extends StatefulWidget {
  final Map<String, dynamic> articleInfo;
  final Function(String, [dynamic])? navigateTo;
  const ArticleInfo({
    super.key,
    required this.articleInfo,
    required this.navigateTo,
  });

  @override
  State<ArticleInfo> createState() => _ArticleInfoState();
}

class _ArticleInfoState extends State<ArticleInfo> {
  final uploadService = UploadService();
  final fetchService = FetchService();
  final convertService = Pdf2HtmlConverter();

  bool hasUpdated = false;
  late Map<String, dynamic> article;

  @override
  void initState() {
    super.initState();
    article = Map<String, dynamic>.from(widget.articleInfo);
    hasUpdated ? loadArticle() : null;
  }

  Future<void> loadArticle() async {
    // final int articleId = widget.articleInfo['id'];
    final int articleId = 3;

    final newArticle = await fetchService.fetchArticleFromServer(
      articleId,
    ); // Replace with your actual method
    if (newArticle['status']) {
      setState(() {
        article = newArticle['article'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Magazine data ${article}');
    final excludedKeys = {
  'id',
  'coverImage',
  'htmlPath',
  'createdAt',
  'updatedAt',
  'adminId',
  'credits', // handled separately
  'html',
  'cover'
};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDE - Editable fields (WIDER)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      article.entries.map((entry) {
                        if (excludedKeys.contains(entry.key)) {
                          return SizedBox(); // handled on the right
                        } else if (entry.key == 'credits' ) {
                          Map<String, dynamic> credits = Map<String, dynamic>.from(article['credits']);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key[0].toUpperCase() +
                                    entry.key.substring(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(fontSize: 16),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await showEditDialog(
                                        context,
                                        entry.key[0].toUpperCase() +
                                            entry.key.substring(1),
                                        entry.value.toString(),
                                      );

                                      // You can handle the result here
                                      if (result != null) {
                                        bool sendToServer = await sendUpdate(
                                          context,
                                          entry.key[0].toUpperCase() +
                                              entry.key.substring(1),
                                          result,
                                        );

                                        if (sendToServer) {
                                          setState(() {
                                            hasUpdated = true;
                                          });
                                          loadArticle();
                                        }
                                      }
                                    },
                                    icon: Icon(Icons.edit),
                                    label: Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ),

        // RIGHT SIDE - Image + action buttons (NARROWER)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // COVER IMAGE
                Text(
                  'Cover Image',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                if (article['cover'] != null &&
                    article['cover'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      article['cover'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Center(child: Text('Image load error')),
                          ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: const Center(child: Text('No cover image')),
                  ),
                const SizedBox(height: 10),

                // Upload & Delete buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement image upload
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          article['cover'] = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Open HTML in browser
                Text(
                  'Magazine File',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Call your convertService.openOnlineHtml here
                    // Example:
                    // convertService.openOnlineHtml(article['html'], article['title']);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in browser'),
                ),

                const SizedBox(height: 10),

                // Upload new document
                ElevatedButton.icon(
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

                      await updateMagFile(context, file);
                      setState(() {
                        hasUpdated = true;
                      });
                      loadArticle();
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload New PDF Document'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> showEditDialog(
    BuildContext context,
    String editField,
    String currentValue,
  ) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $editField'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.multiline,
            maxLines: null, // Expands as user types
            decoration: InputDecoration(
              labelText: editField,
              border: OutlineInputBorder(),
              isDense: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              alignLabelWithHint: true, // Important for multi-line fields
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(controller.text); // Return edited value
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> sendUpdate(
    BuildContext context,
    String editField,
    String newValue,
  ) async {
    // Step 1: Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Update'),
          content: Text(
            'Are you sure you want to update "$editField" to:\n\n"$newValue"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Updating... Please wait.')),
            ],
          ),
        );
      },
    );

    Map<String, dynamic> mapToUpdate = {
      'name': article['title'],
      'field': editField,
      'value': newValue,
    };
    await uploadService.sendUpdateToServer(mapToUpdate);
    Navigator.of(context).pop();

    return true;
  }

  Future<void> updateMagFile(BuildContext context, PlatformFile? newPdf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Update'),
          content: Text(
            'Are you sure you want to update ${article['title']} file?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Updating... Please wait.')),
            ],
          ),
        );
      },
    );

    bool updateFile = await uploadService.processMagazine(newPdf!);
    Navigator.of(context).pop();
  }
}
