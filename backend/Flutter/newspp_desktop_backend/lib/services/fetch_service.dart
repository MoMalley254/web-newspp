import 'package:newspp_desktop_backend/services/toast_service.dart';

class FetchService {
  final toastHelper = ToastService();

  Future<Map<String, dynamic>> fetchArticlesFromServer() async {
    try {
      // Simulated article list with placeholder image URLs
      List<Map<String, dynamic>> articles = [
        {
          'title': 'The Rise of AI Journalism',
          'author': 'John Doe',
          'issue': '42',
          'date': '2025-08-10',
          'tags': 'AI, Journalism, Future',
          'description':
              'An overview of how AI is changing the journalism industry.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=AI+Journalism',
        },
        {
          'title': 'Climate Change and Media Responsibility',
          'author': 'Jane Smith',
          'issue': '43',
          'date': '2025-08-15',
          'tags': 'Climate, Media, Responsibility',
          'description':
              'Examining the role of media in the climate change debate.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=Climate+Media',
        },
        {
          'title': 'The Rise of AI Journalism',
          'author': 'John Doe',
          'issue': '42',
          'date': '2025-08-10',
          'tags': 'AI, Journalism, Future',
          'description':
              'An overview of how AI is changing the journalism industry.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=AI+Journalism',
        },
        {
          'title': 'Climate Change and Media Responsibility',
          'author': 'Jane Smith',
          'issue': '43',
          'date': '2025-08-15',
          'tags': 'Climate, Media, Responsibility',
          'description':
              'Examining the role of media in the climate change debate.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=Climate+Media',
        },
        {
          'title': 'The Rise of AI Journalism',
          'author': 'John Doe',
          'issue': '42',
          'date': '2025-08-10',
          'tags': 'AI, Journalism, Future',
          'description':
              'An overview of how AI is changing the journalism industry.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=AI+Journalism',
        },
        {
          'title': 'Climate Change and Media Responsibility',
          'author': 'Jane Smith',
          'issue': '43',
          'date': '2025-08-15',
          'tags': 'Climate, Media, Responsibility',
          'description':
              'Examining the role of media in the climate change debate.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=Climate+Media',
        },
        {
          'title': 'The Rise of AI Journalism',
          'author': 'John Doe',
          'issue': '42',
          'date': '2025-08-10',
          'tags': 'AI, Journalism, Future',
          'description':
              'An overview of how AI is changing the journalism industry.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=AI+Journalism',
        },
        {
          'title': 'Climate Change and Media Responsibility',
          'author': 'Jane Smith',
          'issue': '43',
          'date': '2025-08-15',
          'tags': 'Climate, Media, Responsibility',
          'description':
              'Examining the role of media in the climate change debate.',
          'html': 'https://kinyua-nexus.co.ke/',
          'cover': 'https://placehold.co/150x200.png?text=Climate+Media',
        },
      ];

      return {'status': true, 'articles': articles};
    } catch (error) {
      print('Error fetching from server $error');
      toastHelper.showErrortoast('Error fetching articles: $error');
      return {'status': false, 'error': error.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchArticleFromServer(int articleId) async {
    try {
      toastHelper.showProcessingtoast(
        'Fetching article data please wait...',
        3,
      );
      await Future.delayed(Duration(seconds: 5));
      Map<String, dynamic> updatedItem = {
        'title': 'Updated Item of AI Journalism',
        'author': 'John Doe',
        'issue': '42',
        'date': '2025-08-10',
        'tags': 'AI, Journalism, Future',
        'description':
            'An updated overview of how AI is changing the journalism industry.',
        'html': 'https://kinyua-nexus.co.ke/',
        'cover': 'https://placehold.co/150x200.png?text=Updated+AI+Journalism',
      };
      return {'status': true, 'article': updatedItem};
    } catch (error) {
      print('Error getting $articleId, error $error');
      toastHelper.showErrortoast('Error fetching Error $error');
      return {'status': false, 'error': error};
    }
  }
}
