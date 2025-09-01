import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newspp_desktop_backend/services/convert_service.dart';
import 'package:newspp_desktop_backend/services/fetch_service.dart';
import 'package:newspp_desktop_backend/services/mags_service.dart';

class ArticlesSection extends StatefulWidget {
  final void Function(String menu, [dynamic arguments]) navigateTo;
  const ArticlesSection({super.key, required this.navigateTo});

  @override
  State<ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends State<ArticlesSection> {
  final MagsService magsService = MagsService();
  final FetchService fetchService = FetchService();
  late Future<Map<String, dynamic>> fetchArticles;
  final Pdf2HtmlConverter convertService = Pdf2HtmlConverter();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchArticles = magsService.getAllMags();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchArticles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !(snapshot.data!['status'] as bool)) {
          return Center(
            child: Text('Error: ${snapshot.data?['error'] ?? 'Unknown error'}'),
          );
        } else if ((snapshot.data!['mags'] as List).isEmpty) {
          return Center(
            child: Text(
              'No Magazines found',
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
          );
        }

        List articles = snapshot.data!['mags'];

        if (articles.isEmpty) {
          return const Center(child: Text('No articles available'));
        }

        int columnCount = 3;

        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(Colors.yellow[600]),
              trackColor: WidgetStateProperty.all(Colors.grey[300]),
              thickness: WidgetStateProperty.all(8),
              radius: Radius.circular(10),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8.0,
              radius: const Radius.circular(8),
              scrollbarOrientation: ScrollbarOrientation.right,
              // thumbColor: Colors.green,
              child: GridView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child:
                              (article['cover'] == null ||
                                      article['cover'].isEmpty)
                                  ? Image.network(
                                    'https://placehold.co/600x400/png?text=Business+Unusual',
                                    fit: BoxFit.cover,
                                  )
                                  : Image.network(
                                    article['cover'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Image.network(
                                          'https://placehold.co/600x400/png?text=Business+Unusual',
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                article['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Issue ${article['issueNumber'] ?? '-'}  ${DateFormat('dd-MM-yyyy').format(DateTime.parse(article['publishDate']))}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                article['publisher'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      convertService.openOnlineHtml(
                                        article['html'],
                                        article['title'],
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text(
                                      'Open in browser',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      widget.navigateTo('Article', article);
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
