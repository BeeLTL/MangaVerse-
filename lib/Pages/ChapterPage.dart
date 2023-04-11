import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:http/retry.dart';
import 'package:mangaweb/model/ChapterModal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter_web_pagination/flutter_web_pagination.dart';


class chapterPage extends StatefulWidget {
  const chapterPage({super.key});

  @override
  State<chapterPage> createState() => _chapterPageState();
}




class _chapterPageState extends State<chapterPage> {
    late  Map<String, dynamic> Chapter;
    bool isloading = true;
      int _currentPage = 0;




    @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
   Chapter = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
 

  }


Future<ChapterModal> _getMangaDetails() async {
  isloading = true;

  final chapterId = Chapter["id"];

  final apiURL = 'https://api.mangadex.org/at-home/server/$chapterId';

  final response = await http.get(Uri.parse(apiURL));

  if (response.statusCode == 200) {
    isloading = false;

    final jsonResponse = json.decode(response.body);
    final baseurl = jsonResponse["baseUrl"];

    final dataSaver = jsonResponse["chapter"]["dataSaver"];

    final chapterHash = jsonResponse["chapter"]["hash"];

    final chapterUrl = List<String>.generate(dataSaver.length, (index) {
      return '$baseurl/data-saver/$chapterHash/${dataSaver[index]}';
    });

     final chapters = ChapterModal(chapterUrl: chapterUrl);
           return chapters;

  }else {
      setState(() {
        isloading = false;
      });
      throw Exception('Failed to load Chapters  ');
    }

  
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Color.fromRGBO(190, 190, 190, 8),

    
  body: FutureBuilder(
    future:  _getMangaDetails() ,
    builder: (context, snapshot) {
      if (snapshot.hasData && !isloading) {
        ChapterModal chapter = snapshot.data as ChapterModal;
        return Column(
          children: [
            Expanded(
              child: Image.network(
                chapter.chapterUrl[_currentPage],
              ),
            ),
            // Paginator
            WebPagination(
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              currentPage: _currentPage,
              totalPage: chapter.chapterUrl.length,
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
);

  }
}