import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// 语言管理类
class LanguageManager {
  // 当前语言索引
  static int currentLanguageIndex = 0;

  // 语言列表
  static const List<String> languages = ['English', '中文'];

  // 获取当前语言
  static String get currentLanguage => languages[currentLanguageIndex];

  // 切换语言
  static void switchLanguage(int index) {
    currentLanguageIndex = index;
  }
}
