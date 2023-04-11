import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mangaweb/model/mangaModal.dart';
import 'package:flutter_web_pagination/flutter_web_pagination.dart';
import 'package:cached_network_image/cached_network_image.dart';


class Debouncer {
  final int delay;
  late VoidCallback action;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
   if(_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delay), action);
  }
  void dispose() => _timer?.cancel();
}


class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}



class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  int currentPage = 1;
  int numberOfPages = 0;
  bool isloading = true;
  List<mangaModal>? _searchedMangas; 
  final _debouncer = Debouncer(delay: 1500);

  
  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }



Future<List<mangaModal>> _getMangasInfo(int pageNumber, {String? title}) async {
  isloading = true;

  final queryParams = {
    'limit': '10',
    'includedTagsMode': 'AND',
    'excludedTagsMode': 'OR',
    'contentRating[]': ['safe'],
    'order[latestUploadedChapter]': 'desc',
    'offset': ((pageNumber - 1) * 10).toString(),
    if (title != null) 'title': title,
  };

  final url = Uri.https('api.mangadex.org', '/manga', queryParams);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    isloading = false;

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    final List<dynamic> mangaList = responseData['data'];
    numberOfPages = (responseData['total'] / 10).ceil();
    final List<mangaModal> mangas = [];

    // Loop through each manga in the list and fetch its cover art ID and image URL
    for (final mangaData in mangaList) {
      final mangaId = mangaData['id'];
      final mangaAttributes = mangaData['attributes'];
      final titleObj = mangaAttributes['title'];
      final title =
          titleObj.containsKey('en') ? titleObj['en'] : titleObj.values.first;

      final coverArtRelationships = mangaData['relationships']
          .where((relationship) => relationship['type'] == 'cover_art')
          .toList();
      final coverArtId = coverArtRelationships.isNotEmpty
          ? coverArtRelationships[0]['id']
          : null;
      final coverImageUrl = await _getCoverImageUrl(coverArtId, mangaId);

      mangas.add(mangaModal(
        Mangaid:mangaId,
        Titre: title,
        MangaCover: coverImageUrl,
      ));
    }
    return mangas;
  } else {
    setState(() {
      isloading = false;
    });
    throw Exception('Failed to fetch mangas');
  }
}

// Helper function to fetch the cover image URL based on the cover art ID
  Future<String> _getCoverImageUrl(String? coverArtId, String? mangaId) async {
    if (coverArtId == null) {
      return '';
    }

    final url = Uri.https('api.mangadex.org', '/cover/$coverArtId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final coverImageUrl = responseData['data']['attributes']['fileName'];
      return 'https://uploads.mangadex.org/covers/$mangaId/$coverImageUrl';
    } else {
      throw Exception('Failed to fetch cover image');
    }
  }
    //function method to fetch data with search query
  Future<void> _refreshMangasInfo() async {

          if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final mangas = await _getMangasInfo(currentPage, title: _searchQuery);
      setState(() {
        // Assign the new data to a new variable
        _searchedMangas = mangas;
      });
    } else {
    final mangas = await _getMangasInfo(currentPage);
    setState(() {
      _searchedMangas = mangas;
    });
  }
   



  }

  @override
  Widget build(BuildContext context) {


    return  Scaffold(
      body: Column(
        children: [
          // Search Bar
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: 40,

                  child: TextField(
                    controller: _searchController,
                     onChanged: (value) {
                      // Step 2: Assign search query and call refresh method
                      setState(() {
                        _searchQuery = value.trim();
                      });
                      // Call debouncer with refresh method
                      _debouncer.run(() => _refreshMangasInfo());
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8), 

                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder(
              future:_searchedMangas != null
                  ? Future.value(_searchedMangas) // Return searched mangas if available
                  : _getMangasInfo(currentPage),
              builder: (context, snapShot) {
                if (snapShot.hasData && !isloading) {
                  List<mangaModal> mangas = snapShot.data as List<mangaModal>;
                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10),
                            itemBuilder: ((context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                //rectangle
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/manga', arguments: mangas[index]);
                                  },
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: CachedNetworkImage(
                                            imageUrl: '${mangas[index].MangaCover}',
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(child: CircularProgressIndicator()),
                                            errorWidget: (context, url, error) =>
                                                Icon(Icons.error),
                                          ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Text(
                                              mangas[index].Titre,
                                              style: const TextStyle(fontSize: 15),
                                              textAlign: TextAlign.center,
                                            ))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            itemCount: mangas.length,
                          ),
                        ),
                      ),
                      // Paginator
                      WebPagination(
                        onPageChanged: (page) {
                          setState(() {
                            currentPage = page;
                          });
                        },
                        currentPage: currentPage,
                        totalPage: numberOfPages,
                      ),
                    ],
                  );
                } else if (isloading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
 