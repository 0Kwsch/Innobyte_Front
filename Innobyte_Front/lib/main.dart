// main.dart - 앱 진입점 및 상태 관리
import 'package:flutter/material.dart';

// 분리된 파일들을 임포트합니다.
import 'login.dart';
import 'screens/notes_screen.dart';

/// 앱의 시작점 - 메인 함수
void main() {
  runApp(const SamsungNotesApp());
}

// ====================================================
// 2. 메인 애플리케이션 및 상태 관리 (최상위)
// ====================================================

/// 삼성 노트 앱의 최상위 위젯
class SamsungNotesApp extends StatefulWidget {
  const SamsungNotesApp({super.key});

  @override
  State<SamsungNotesApp> createState() => _SamsungNotesAppState();
}

/// 삼성 노트 앱의 상태를 관리하는 클래스
class _SamsungNotesAppState extends State<SamsungNotesApp> {
  // ⭐ 기본 테마를 다크 모드로 설정
  ThemeMode themeMode = ThemeMode.dark;
  bool _isLoggedIn = false;

  /// 테마 전환 기능
  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  /// 로그인 성공 시 앱 상태를 로그인됨으로 전환하는 기능
  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  /// 앱의 UI 빌드 및 테마 설정 기능
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samsung Notes Clone',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      // ⭐ 라이트 테마: 밝은 회색 베이스
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
        cardColor: Colors.white,
      ),

      // ⭐ 다크 테마: 검정/짙은 회색 베이스
      darkTheme: ThemeData(
          primarySwatch: Colors.grey,
          scaffoldBackgroundColor: const Color(0xFF121212), // 짙은 검정 배경
          brightness: Brightness.dark,
          cardColor: const Color(0xFF1E1E1E), // 카드/컨테이너 배경색
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white70),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
          )
      ),

      // ⭐ 홈 화면: LoginScreen에 필수 매개변수 전달하여 오류 해결
      home: _isLoggedIn
          ? NotesHomePage(onToggleTheme: toggleTheme, currentTheme: themeMode)
          : LoginScreen(
        onLoginSuccess: _onLoginSuccess,
        onToggleTheme: toggleTheme,
        currentTheme: themeMode,
      ),
    );
  }
}