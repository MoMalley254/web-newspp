import 'package:flutter/material.dart';

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
  late Map<String, dynamic> article;

  @override
  void initState() {
    super.initState();
    article = Map<String, dynamic>.from(
      widget.articleInfo,
    ); // make editable copy
  }

  void onEditField(String key, String newValue) {
    setState(() {
      article[key] = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        if (entry.key == 'cover' || entry.key == 'html') {
                          return SizedBox(); // handled on the right
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
                              TextFormField(
                                initialValue: entry.value.toString(),
                                onChanged:
                                    (value) => onEditField(entry.key, value),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
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
                  onPressed: () {
                    // TODO: Implement document upload
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
