import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/fetch_service.dart';
import 'package:newspp_desktop_backend/services/mags_service.dart';
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
  final magsService = MagsService();

  bool hasUpdated = false;
  late Map<String, dynamic> article;

  PlatformFile? _coverImage;

  @override
  void initState() {
    super.initState();
    article = Map<String, dynamic>.from(widget.articleInfo);
    hasUpdated ? loadArticle() : null;
  }

  Future<void> loadArticle() async {
    final String articleId = widget.articleInfo['id'];

    // final newArticle = await fetchService.fetchArticleFromServer(
    //   articleId,
    // );

    final newArticle = await magsService.fetchSingleMagazine(articleId);
    if (newArticle['status']) {
      setState(() {
        article = newArticle['magazine'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Image url ${article}');
    final excludedKeys = {
      'id',
      'coverImage',
      'htmlPath',
      'createdAt',
      'updatedAt',
      'adminId',
      'html',
      'cover',
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
                        } else if (entry.key == 'credits') {
                          Map<String, dynamic> credits =
                              Map<String, dynamic>.from(article['credits']);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Credits',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                children:
                                    credits.entries.map((entry) {
                                      final value = entry.value;
                                      Widget valueWidget;
                                      String valueToPass;

                                      if (value is List) {
                                        // Handle list of contributors
                                        valueToPass = value.join(',');
                                        valueWidget = Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children:
                                              value.map<Widget>((creditor) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      creditor.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                    ),
                                                    const SizedBox(height: 5),
                                                  ],
                                                );
                                              }).toList(),
                                        );
                                      } else {
                                        valueToPass = value.toString();
                                        valueWidget = Text(
                                          value.toString(),
                                          style: const TextStyle(fontSize: 16),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.key[0].toUpperCase() +
                                                      entry.key.substring(1),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: valueWidget,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  final result =
                                                      await showEditDialog(
                                                        context,
                                                        entry.key[0]
                                                                .toUpperCase() +
                                                            entry.key.substring(
                                                              1,
                                                            ),
                                                        valueToPass,
                                                      );

                                                  if (result != null) {
                                                    bool sendToServer =
                                                        await sendUpdate(
                                                          context,
                                                          'credits : ${entry.key}',
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
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ],
                          );
                        } else if (entry.key == 'publishDate') {
                          final publishDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.parse(entry.value));
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
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          publishDate,
                                          style: const TextStyle(fontSize: 16),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        // final result = await showEditDialog(
                                        //   context,
                                        //   entry.key[0].toUpperCase() +
                                        //       entry.key.substring(1),
                                        //   publishDate,
                                        // );
                                        final result =
                                            await showDatePickerDialog(
                                              context,
                                              DateTime.parse(entry.value),
                                            );

                                        // You can handle the result here
                                        if (result != null) {
                                          bool sendToServer = await sendUpdate(
                                            context,
                                            entry.key,
                                            result.toString(),
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
                                          entry.key,
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
                if (article['cover'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      article['cover'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        final imageUrl = article['cover'];
                        print('❌ Failed to load image: $imageUrl');
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(child: Text('Image load error')),
                        );
                      },
                    ),
                  )
                else if (_coverImage != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: Center(child: Text('Image: ${_coverImage!.name}')),
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

                          // final confirm = await showEditDialog(
                          //               context,
                          //               'coverImage',
                          //               '',
                          //             );

                          // You can handle the result here
                          // if (confirm != null) {
                          bool sendToServer = await sendUpdate(
                            context,
                            'coverImage',
                            result.files.first.path!,
                          );

                          if (sendToServer) {
                            setState(() {
                              hasUpdated = true;
                            });
                            loadArticle();
                          }
                          // }
                        }
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
                    convertService.openOnlineHtml(
                      article['html'],
                      article['title'],
                    );
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
                      if (file.size > 500 * 1024 * 1024) {
                        toastification.show(
                          title: Text(
                            'PDF exceeds 500MB limit. Please choose a smaller file.',
                          ),
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          autoCloseDuration: const Duration(seconds: 5),
                        );
                        return;
                      }

                      await updateMagFile(context, file, article['htmlPath']);
                      setState(() {
                        hasUpdated = true;
                      });
                      loadArticle();
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload New PDF Document'),
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: () {
                    deleteMag(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    'Delete Magazine',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red button background
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
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
    final formattedValue =
        editField == 'publishDate'
            ? DateFormat('dd-MM-yyyy').format(DateTime.parse(newValue))
            : newValue.toString();
    // Step 1: Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Update'),
          content: Text(
            'Are you sure you want to update "$editField" to:\n\n"$formattedValue"?',
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
    // return false;

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
      'id': article['id'],
      'name': article['title'],
      'field': editField,
      'value': newValue,
    };

    await magsService.updateMagazine(
      mapToUpdate,
      editField == 'htmlPath' || editField == 'coverImage',
    );

    // await uploadService.sendUpdateToServer(mapToUpdate);
    Navigator.of(context).pop();

    return true;
  }

  Future<void> updateMagFile(
    BuildContext context,
    PlatformFile? newPdf,
    String pagesPath,
  ) async {
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

    // bool updateFile = await uploadService.processMagazine(newPdf!);
    bool updateFile = await magsService.processMagazine(
      newPdf!,
      article['id'],
      article['title'],
      pagesPath,
    );
    Navigator.of(context).pop();
  }

  Future<void> deleteMag(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.delete_forever, color: Colors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Confirm Deletion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${article['title'] ?? 'this item'}"?\n\nThis action is irreversible.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Deleting... Please wait.')),
            ],
          ),
        );
      },
    );

    final articleId = article['id'];
    bool deleteSuccess = await magsService.deleteMagazine(articleId);

    Navigator.of(context).pop(); // Close the loading dialog

    if (deleteSuccess) {
      widget.navigateTo?.call('Dashboard');
    }
  }

  Future<DateTime?> showDatePickerDialog(
    BuildContext context,
    DateTime initialDate,
  ) async {
    final List<DateTime?>? pickedDates = await showDialog<List<DateTime?>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a date'),
          content: SizedBox(
            width: 300, // Explicit width
            height: 400, // Explicit height to contain the calendar
            child: CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.single,
              ),
              value: [initialDate],
              onValueChanged: (dates) {
                Navigator.of(context).pop(dates);
              },
            ),
          ),
        );
      },
    );

    return pickedDates?.first;
  }
}
