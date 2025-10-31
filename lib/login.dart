// login.dart 파일 내용 .ㅇd

import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // ⭐ API 연결 시 주석 해제
import 'package:flutter/services.dart';

/// 앱 진입 시 사용자 인증을 위한 로그인 화면을 표시
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onToggleTheme; // 테마 전환 기능
  final ThemeMode currentTheme; // 현재 테마 모드

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onToggleTheme,
    required this.currentTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Google Sign-In 로직을 처리하는 클래스
class _LoginScreenState extends State<LoginScreen> {
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // ⭐ API 연결 로직: GoogleSignIn 인스턴스 생성

  bool _isLoading = false;
  String? _errorMessage;

  /// Google Sign-In 버튼 클릭 처리 기능 (더미 로직 포함)
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ⭐ API 연결 로직: 실제 Google 인증을 요청하는 코드 (주석 처리됨)
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // UI 테스트를 위한 지연 및 강제 성공
      await Future.delayed(const Duration(seconds: 2));

      // 로그인 성공
      widget.onLoginSuccess();
    } catch (error) {
      // ⭐ API 연결 로직: 실제 오류 처리
      // TODO: 실제 로깅 시스템 구현 필요
      setState(() {
        _errorMessage = 'Google 로그인 중 오류가 발생했습니다. 설정을 확인하세요.';
        _isLoading = false;
      });
    }
  }

  /// 메모리 정리
  @override
  void dispose() {
    super.dispose();
  }

  /// 로그인 화면의 UI 레이아웃을 구성
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF678AFB);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      // ⭐ AppBar를 사용하여 systemOverlayStyle 및 테마 버튼 배치
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(''),
        actions: [
          IconButton(
            icon: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: textColor,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDarkMode
              ? Brightness.light
              : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 앱 아이콘 및 메시지
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.note_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Samsung Notes에 오신 것을 환영합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Google 계정으로 빠르게 로그인하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                ),
                const SizedBox(height: 32),

                // 에러 메시지
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                // Google 로그인 버튼 (검정/회색 베이스에 맞춰 UI 조정)
                OutlinedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.account_circle, size: 24);
                            },
                          ),
                        ),
                  label: Text(
                    _isLoading ? '로그인 중...' : 'Google로 로그인',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: textColor.withValues(alpha: 0.5)),
                    // ⭐ 다크 모드 버튼 배경색 (짙은 회색)
                    backgroundColor: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Google 계정으로 로그인하시면 노트가 자동으로 동기화됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
