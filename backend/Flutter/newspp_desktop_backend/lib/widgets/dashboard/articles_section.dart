import 'package:flutter/material.dart';
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
  final magsSevice = MagsService();

  final fetchService = FetchService();
  late Future<Map<String, dynamic>> fetchArticles;

  final convertService = Pdf2HtmlConverter();

  @override
  void initState() {
    super.initState();
    // fetchArticles = fetchService.fetchArticlesFromServer();
    fetchArticles = magsSevice.getAllMags();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
        } else if (snapshot.data!['mags'].isEmpty) {
          return Center(
            child: Text(
              'No Magazines found',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
          );
        }

        print('Mags found ${snapshot.data!['mags']}');

        List articles = snapshot.data!['mags'];

        if (articles.isEmpty) {
          return const Center(child: Text('No articles available'));
        }

        // int columnCount = (articles.length >= 3) ? 3 : articles.length;
        int columnCount = 3;

        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final itemHeight = constraints.maxHeight * 0.2;
                  return SizedBox(
                    height: itemHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Background image
                          Positioned.fill(
                            child:
                                (article['coverImage'] == null ||
                                        article['coverImage'].isEmpty)
                                    ? Image.network(
                                      'https://placehold.co/150x150?text=Business+Unusual', // your placeholder URL
                                      fit: BoxFit.cover,
                                    )
                                    : Image.network(
                                      article['coverImage'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Image.network(
                                            'https://placehold.co/150x150?text=Business+Unusual', // fallback placeholder on error
                                            fit: BoxFit.cover,
                                          ),
                                    ),
                          ),

                          // Gradient overlay
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

                          // Text info
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Issue ${article['issue']} - ${article['date']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  article['publisher'],
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
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
                                      icon: Icon(
                                        Icons.open_in_new,
                                      ), // icon representing "open in another app"
                                      label: Text(
                                        'Open in browser',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Navigate to the magazine info page
                                        widget.navigateTo('Article', article);
                                      },
                                      icon: Icon(Icons.info_outline),
                                      label: Text('Edit'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
