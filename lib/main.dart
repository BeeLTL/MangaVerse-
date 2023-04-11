import 'package:flutter/material.dart';
import 'package:mangaweb/Pages/home.dart';
import 'package:mangaweb/Pages/MangaPage.dart';
import 'package:mangaweb/Pages/ChapterPage.dart';



 void main() => runApp(
  MaterialApp(
    initialRoute: "/",
    routes: {
      '/' : (context) => Home(),
      '/manga' : (context) => MangaPage(),
      '/chapter' : (context) => chapterPage(),
    },
  )

 );