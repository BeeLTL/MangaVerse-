import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:http/retry.dart';
import 'package:mangaweb/model/mangaModal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'package:mangaweb/model/mangaDetailsModal.dart';

// import 'package:html/dom.dart' as dom;

class MangaPage extends StatefulWidget {
  const MangaPage({super.key});

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  late mangaModal manga;
  bool isloading = true;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    manga = ModalRoute.of(context)!.settings.arguments as mangaModal;
  }

  Future<MangaDetails> _getMangaDetails() async {
    isloading = true;
    final mangaId = manga.Mangaid;
    final apiURL = 'https://api.mangadex.org/manga/$mangaId';

    final response = await http.get(Uri.parse(apiURL));
    if (response.statusCode == 200) {
      isloading = false;

      final jsonResponse = json.decode(response.body);

      final title = jsonResponse['data']['attributes']['title']['en'];
      final altTitlesRaw = jsonResponse['data']['attributes']['altTitles'];
      final altTitles = altTitlesRaw
          .map((e) =>
              e.values.firstWhere((value) => value != null, orElse: () => ''))
          .join(', ')
          .toString();
     final String originalDescription = jsonResponse['data']['attributes']['description']['en'].toString();
final int newlineIndex = originalDescription.indexOf("---");
final String description = newlineIndex != -1 ? originalDescription.substring(0, newlineIndex) : originalDescription;
          
      final tagsRaw = jsonResponse['data']['attributes']['tags'];
      final tags = List<String>.from(
          tagsRaw.map((e) => e['attributes']['name']['en'].toString()));
      final tagsString = tags.join(", ");
      final status = jsonResponse['data']['attributes']['status'].toString();
      final year = jsonResponse['data']['attributes']['year'].toString();

      final chapters = await _getChapters(mangaId);

      final mangaDetails = MangaDetails(
        title: title,
        altTitles: altTitles,
        description: description,
        status: status,
        tags: tagsString,
        year: year,
        image: manga.MangaCover,
        chapters: chapters,
      );
      return mangaDetails;
    } else {
      setState(() {
        isloading = false;
      });
      throw Exception('Failed to load manga details');
    }
  }

  Future<List<Map<String, String>>> _getChapters(String mangaId) async {
    final apiURL = 'https://api.mangadex.org/manga/$mangaId/feed';
    final chapters = <Map<String, String>>[];
    int offset = 0;
    int limit = 100;
    int totalChapters = 0;

    final totalResponse = await http.get(Uri.parse('$apiURL?limit=1'));
    if (totalResponse.statusCode == 200) {
      final totalJsonResponse = json.decode(totalResponse.body);
      totalChapters = totalJsonResponse['total'];
    } else {
      throw Exception('Failed to load chapters');
    }

    int totalPages = (totalChapters / limit).ceil();
    bool hasNextPage = true;

    for (int page = 1; page <= totalPages && hasNextPage; page++) {
      final response = await http.get(Uri.parse(
          '$apiURL?limit=$limit&offset=$offset&translatedLanguage[]=en'));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'];
        if (data.isEmpty) {
          hasNextPage = false;
          break;
        }

        final List<dynamic> chapterData =
            data.where((item) => item['type'] == 'chapter').toList();
        final chaptersForPage = <Map<String, String>>[];
        for (var item in chapterData) {
          final attributes = item['attributes'];
          final chapterMap = <String, String>{
            'id': item['id'] ?? '',
            'title': attributes['title'] ?? '',
            'volume': attributes['volume'] ?? '',
            'chapter': attributes['chapter'] ?? ''
          };
          chaptersForPage.add(chapterMap);
        }
        chapters.addAll(chaptersForPage);

        offset += limit;
      } else {
        throw Exception('Failed to load chapters');
      }
    }

    // Sort the chapters list by volume and chapter in ascending order
    chapters.sort((a, b) {
      int aVolume =
          int.tryParse(a['volume']?.split(',').first.trim() ?? '') ?? 0;
      int bVolume =
          int.tryParse(b['volume']?.split(',').first.trim() ?? '') ?? 0;
      double aChapter = double.tryParse(a['chapter']?.trim() ?? '') ?? 0;
      double bChapter = double.tryParse(b['chapter']?.trim() ?? '') ?? 0;
      if (aVolume != bVolume) {
        return aVolume.compareTo(bVolume);
      } else {
        int aChapterInt = aChapter.truncate();
        int bChapterInt = bChapter.truncate();
        if (aChapterInt != bChapterInt) {
          return aChapterInt.compareTo(bChapterInt);
        } else {
          double aChapterDecimal = aChapter % 1;
          double bChapterDecimal = bChapter % 1;
          return aChapterDecimal.compareTo(bChapterDecimal);
        }
      }
    });

    return chapters;
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<Map<String, String>>> _volumes = {};

    return Scaffold(
      backgroundColor: Color.fromRGBO(190, 190, 190, 8),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 200),
          child: SizedBox(
            child: FutureBuilder(
              future: _getMangaDetails(),
              builder: (context, snapshot) {
                if (snapshot.hasData && !isloading) {
                  MangaDetails manga = snapshot.data as MangaDetails;
                  List<Map<String, String>> chapters = manga.chapters;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        child: Image.network(
                          manga.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                manga.title,
                                style: const TextStyle(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'Alternative Names: ${manga.altTitles}',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Status: ${manga.status}',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Release Date: ${manga.year}',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Genres: ${manga.tags}',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 16.0),
                              const Text(
                                'Synopsis',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                manga.description,
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 16.0),
                              const Text(
                                'Chapters',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: chapters.length,
                                  itemBuilder: (context, index) {
                                    final chapter = chapters[index];
                                    String? volumeStr = chapter['volume'];
                                    int volume =
                                        int.tryParse(volumeStr ?? "") ?? 0;
                                    // Create a new list for each volume
                                    if (!_volumes.containsKey(volume)) {
                                      _volumes[volume] = [];
                                    }

                                    // Add chapter to the list of chapters under the volume
                                    _volumes[volume]!.add(chapter);

                                    // Check if we have processed all chapters
                                    if (index == chapters.length - 1) {
                                      // Build the list of volumes
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _volumes.length,
                                        itemBuilder: (context, index) {
                                          final volume =
                                              _volumes.keys.elementAt(index);
                                          final chapters = _volumes[volume]!;

                                          return ExpansionTile(
                                            title: Text('Volume $volume'),
                                            children: chapters
                                                .map((chapter) => ListTile(
                                                  onTap: () {
                                                  Navigator.pushNamed(context, '/chapter',arguments: chapter );

                                                  },
                                                      title: Text(
                                                          'Chapter ${chapter['chapter']}'),
                                                    ))
                                                .toList(),
                                          );
                                        },
                                      );
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
