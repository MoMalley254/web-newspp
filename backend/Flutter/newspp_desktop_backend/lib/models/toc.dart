class TocEntry {
  String title;
  String subtitle;
  String pages; // comma-separated string

  TocEntry({this.title = '', this.subtitle = '', this.pages = ''});

  @override
  String toString() {
    return 'Title: $title, Subtitle: $subtitle, Pages: $pages';
  }
}
