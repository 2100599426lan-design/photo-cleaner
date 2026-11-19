import 'package:flutter/material.dart';

import 'ui/root_page.dart';

/// 应用根组件：主题与首页。
class PhotoCleanerApp extends StatelessWidget {
  const PhotoCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '照片整理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F6DF5),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F6DF5),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const RootPage(),
    );
  }
}
