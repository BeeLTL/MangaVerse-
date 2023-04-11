class MangaDetails {
  String title;
  String altTitles;
  String description;
  String tags;
  String year;
  String status;
  String image;
  List<Map<String, String>> chapters;

  MangaDetails({
    required this.title,
    required this.altTitles,
    required this.description,
    required this.status,
    required this.tags,
    required this.year,
    required this.image,
    required this.chapters,

  });
}
