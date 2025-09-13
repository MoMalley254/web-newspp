import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newspp_desktop_backend/models/toc.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/fetch_service.dart';
import 'package:newspp_desktop_backend/services/mags_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
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
  final toastHelper = ToastService();

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
                          if (article['credits'] == null ||
                              article['credits'] is! Map) {
                            return SizedBox.shrink();
                          }
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
                        } else if (entry.key == 'links') {
                          return Column(
                            children: [
                              Text(
                                entry.key[0].toUpperCase() +
                                    entry.key.substring(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (article['links'] == null ||
                                  article['links'].isEmpty)
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await showAddLinks(context);

                                    if (result != null && result.isNotEmpty) {
                                      bool sendToServer = await sendUpdate(
                                        context,
                                        'links',
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
                                  child: const Text('Add Links'),
                                ),

                              if (article['links'].isNotEmpty)
                                buildShowLinks(context, article['links']),

                              const SizedBox(height: 20,),
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
                        } else if (entry.key == 'hasToc' ||
                            entry.key == 'tableOfContents') {
                          return Column(
                            children: [
                              Text(
                                'Table of Contents',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              tableOfContents(context, entry.value),
                            ],
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

  Widget tableOfContents(BuildContext context, bool hasToc) {
    if (!hasToc) {
      return ElevatedButton(
        onPressed: () async {
          await addTableOfContents(context);
        },
        child: Text('Add Table of Contents'),
      );
    } else {
      return FutureBuilder(
        future: magsService.getTocs(article['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Getting contents...'),
              ],
            );
          } else if (snapshot.hasError || !snapshot.data!['status']) {
            final error =
                snapshot.error ?? snapshot.data?['error'] ?? 'Unknown error';
            return Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(7),
              ),
              margin: EdgeInsets.only(top: 7, bottom: 7),
              padding: EdgeInsets.only(top: 7, bottom: 7, left: 3, right: 3),
              child: Text(
                'Error : $error',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            List<dynamic> tocs = snapshot.data!['tocs'];
            return tocs.isNotEmpty
                ? Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      buildTocs(context, tocs),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('Remove Table of Contents'),
                                        content: Text(
                                          'Are you sure you want to remove all TOC entries?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: Text('Remove'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  await removeTableOfContents(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                'Remove Table of Contents',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () async {
                                await addTableOfContents(context);
                              },
                              child: Text('Add Table of Contents'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  width: MediaQuery.of(context).size.width * .9,
                  margin: EdgeInsets.only(top: 7, bottom: 7),
                  padding: EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    left: 3,
                    right: 3,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No contents available please create some',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await addTableOfContents(context);
                        },
                        child: Text('Add Table of Contents'),
                      ),
                    ],
                  ),
                );
          }
        },
      );
    }
  }

  Widget buildTocs(BuildContext context, List<dynamic> tocs) {
    return Column(
      children:
          tocs.map<Widget>((toc) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title

                    // Subtitle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: 'Title: \n',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: toc['title'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await editTocTitle(
                              context,
                              toc['id'],
                              toc['title'],
                            );
                          },
                          child: Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: 'Subtitle: \n',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: toc['subTitle'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await editTocSubtitle(
                              context,
                              toc['id'],
                              toc['subTitle'],
                            );
                          },
                          child: Text('Edit'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Pages
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: 'Pages: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: toc['pages'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await editTocPages(
                              context,
                              toc['id'],
                              toc['pages'],
                            );
                          },
                          child: Text('Edit'),
                        ),
                      ],
                    ),

                    // Delete button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Remove ${toc['title']}'),
                                  content: Text(
                                    'Are you sure you want to remove this table of content entry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text('Remove'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            await deleteToc(context, toc['id']);
                          }
                        },
                        icon: Icon(Icons.delete, color: Colors.red),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<String?> showAddLinks(BuildContext context) async {
    final _siteController = TextEditingController();
    final _urlController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Social Link'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _siteController,
                    decoration: const InputDecoration(
                      labelText: 'Site (e.g., YouTube)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a site name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'URL'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a URL';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // returns null
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newLink =
                        '${_siteController.text.trim()} -- ${_urlController.text.trim()}';
                    Navigator.pop(context, newLink); // ✅ pass back result
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Widget buildShowLinks(BuildContext context, List<dynamic> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          ...links.map<Widget>((link) {
            final site = link.split('--')[0];
            final url = link.split('--')[1].trim();

            final style = _getSocialStyle(site);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(style['icon'], color: style['color']),
                  const SizedBox(width: 8),
                  Text(
                    '$site:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: style['color'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: style['color'],
                      ),
                      onPressed: () async {
                        convertService.openOnlineHtml(url, site.trim());
                      },
                      child: Text(
                        url,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.amberAccent,
                      tooltip: 'Delete',
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Text('Updating... Please wait.'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        bool deleteLink = await magsService.deleteOneLink(
                          link,
                          article['id'],
                        );

                        Navigator.of(context).pop();

                        if (deleteLink) {
                          setState(() {
                            hasUpdated = true;
                          });
                          loadArticle();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ElevatedButton(
                                  onPressed: () async {
                                    final result = await showAddLinks(context);

                                    if (result != null && result.isNotEmpty) {
                                      bool sendToServer = await sendUpdate(
                                        context,
                                        'links',
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
                                  child: const Text('Add Links'),
                                ),
      ]
    );
  }

  Map<String, dynamic> _getSocialStyle(String site) {
    switch (site.toLowerCase().trim()) {
      case 'youtube':
        return {'color': Color(0xFFFF0000), 'icon': Icons.play_circle_fill};
      case 'instagram':
        return {'color': Color(0xFFC13584), 'icon': Icons.camera_alt};
      case 'tiktok':
        return {'color': Color(0xFF010101), 'icon': Icons.music_note};
      case 'facebook':
        return {'color': Color(0xFF1877F2), 'icon': Icons.facebook};
      case 'twitter':
        return {'color': Color(0xFF1DA1F2), 'icon': Icons.chat};
      case 'linkedin':
        return {'color': Color(0xFF0A66C2), 'icon': Icons.work};
      default:
        return {'color': Colors.grey, 'icon': Icons.link};
    }
  }

  Future<void> addTableOfContents(BuildContext context) async {
    List<TocEntry> entries = [TocEntry()];

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Table of Contents'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ...entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final toc = entry.value;

                      return Padding(
                        key: ValueKey(index),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Text(
                              'Entry ${index + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: toc.title,
                              decoration: InputDecoration(labelText: 'Title'),
                              onChanged: (val) => toc.title = val,
                            ),
                            SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: toc.subtitle,
                                    decoration: InputDecoration(
                                      labelText: 'Subtitle (optional)',
                                    ),
                                    onChanged: (val) => toc.subtitle = val,
                                  ),
                                ),
                                SizedBox(width: 8),

                                // Pages
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: toc.pages,
                                    decoration: InputDecoration(
                                      labelText: 'Pages (e.g. 1,2,3)',
                                    ),
                                    onChanged: (val) => toc.pages = val,
                                  ),
                                ),
                                SizedBox(width: 8),

                                // Remove button
                                if (index != 0)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        entries.removeAt(index);
                                      });
                                    },
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Remove entry',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Add Entry button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            entries.add(TocEntry());
                          });
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add Entry'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    List<Map<String, dynamic>> cleanedTocs = [];
                    for (var e in entries) {
                      if (e.title.isEmpty || e.pages.isEmpty) {
                        toastHelper.showWarningtoast(
                          'Please fill in all field or remove unused fields',
                        );
                        return;
                      } else {
                        Map<String, dynamic> toc = {
                          'title': e.title,
                          'subTitle': e.subtitle,
                          'pages': e.pages,
                        };
                        cleanedTocs.add(toc);
                      }
                      // Navigator.of(context).pop();
                    }

                    Navigator.of(context).pop();

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

                    bool addedTocs = await magsService.addTocs(
                      article['id'],
                      cleanedTocs,
                    );
                    Navigator.of(context).pop();
                    if (addedTocs) {
                      setState(() {
                        hasUpdated = true;
                      });
                      loadArticle();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> removeTableOfContents(BuildContext context) async {
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

    bool deletedTocs = await magsService.removeTocs(article['id']);
    Navigator.of(context).pop();
    if (deletedTocs) {
      setState(() {
        hasUpdated = true;
      });
      loadArticle();
    }
  }

  Future<void> editTocTitle(
    BuildContext context,
    String tocId,
    String currentValue,
  ) async {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != currentValue) {
                  bool updatedTocTitle = await magsService.editSingleToc(
                    tocId,
                    'title',
                    newTitle,
                  );
                  if (updatedTocTitle) {
                    setState(() {
                      hasUpdated = true;
                    });
                    loadArticle();
                  }
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  toastHelper.showWarningtoast('Please fill in all fields');
                  return;
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editTocSubtitle(
    BuildContext context,
    String tocId,
    String currentValue,
  ) async {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Subtitle'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Subtitle',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSubtitle = controller.text.trim();
                if (newSubtitle.isNotEmpty && newSubtitle != currentValue) {
                  print('Updated subtitle for $tocId: $newSubtitle');

                  bool updatedTocTitle = await magsService.editSingleToc(
                    tocId,
                    'subTitle',
                    newSubtitle,
                  );
                  if (updatedTocTitle) {
                    setState(() {
                      hasUpdated = true;
                    });
                    loadArticle();
                  }
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  toastHelper.showWarningtoast('Please fill in all fields');
                  return;
                }
                // Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editTocPages(
    BuildContext context,
    String tocId,
    String currentValue,
  ) async {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Pages'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Pages (comma-separated)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPages = controller.text.trim();
                if (newPages.isNotEmpty && newPages != currentValue) {
                  bool updatedTocTitle = await magsService.editSingleToc(
                    tocId,
                    'pages',
                    newPages,
                  );
                  if (updatedTocTitle) {
                    setState(() {
                      hasUpdated = true;
                    });
                    loadArticle();
                  }
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  toastHelper.showWarningtoast('Please fill in all fields');
                  return;
                }
                // Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteToc(BuildContext context, String tocId) async {
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

    bool deletToc = await magsService.deleteOneToc(tocId);
    Navigator.of(context).pop();
    if (deletToc) {
      setState(() {
        hasUpdated = true;
      });
      loadArticle();
    }
  }
}
