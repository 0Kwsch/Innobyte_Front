// constants.dart
// 앱 전체에서 사용하는 상수값 정의 (색상, 크기, 텍스트 등)

import 'package:flutter/material.dart';

// ==================== 색상 상수 ====================
class AppColors {
  // 메인 색상
  static const Color primaryColor = Color(0xFF678AFB);
  static const Color primaryDark = Color(0xFF5865F2);

  // 배경색
  static const Color backgroundLight = Color(0xFFF0F0F0);
  static const Color backgroundDark = Color(0xFF121212);

  // 사이드바 색상
  static const Color sidebarDark = Color(0xFF3E3E3E);
  static const Color sidebarHeaderDark = Color(0xFF2A2A2A);
  static const Color sidebarHoverDark = Color(0xFF5A5A5A);

  // 헤더 색상
  static const Color headerDark = Color(0xFF5A5A5A);

  // 텍스트 색상
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Colors.white54;

  // 아이콘 색상
  static const Color iconPrimary = Colors.white;
  static const Color iconSecondary = Colors.white70;

  // 테마별 색상
  static const Map<String, Color> folderColors = {
    'red': Colors.red,
    'orange': Colors.orange,
    'yellow': Colors.yellow,
    'green': Colors.green,
    'blue': Colors.blue,
    'purple': Colors.purple,
    'pink': Colors.pink,
  };
}

// ==================== 크기 상수 ====================
class AppSizes {
  // 사이드바 크기
  static const double sidebarExpandedWidth = 280;
  static const double sidebarCollapsedWidth = 70;
  static const double sidebarAnimationDuration = 300; // milliseconds

  // 아이콘 크기
  static const double iconSmall = 16;
  static const double iconMedium = 18;
  static const double iconLarge = 20;
  static const double iconXLarge = 24;

  // 패딩
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 20;
  static const double paddingXXLarge = 32;

  // 글자 크기
  static const double fontSmall = 12;
  static const double fontMedium = 14;
  static const double fontLarge = 16;
  static const double fontXLarge = 18;
  static const double fontXXLarge = 22;
  static const double fontXXXLarge = 24;

  // 보더 반지름
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 15;
  static const double radiusXLarge = 18;
  static const double radiusRound = 20;

  // 그리드뷰 설정
  static const double gridViewItemAspectRatio = 0.75;
  static const double gridViewCrossAxisSpacing = 15;
  static const double gridViewMainAxisSpacing = 15;
  static const double gridViewMinWidth = 200;
  static const int gridViewMinCrossAxisCount = 2;
  static const int gridViewMaxCrossAxisCount = 6;
}

// ==================== 텍스트 상수 ====================
class AppText {
  // 사이드바 메뉴
  static const String sidebarAllNotes = '모든 노트';
  static const String sidebarStarred = '즐겨찾기';
  static const String sidebarRecent = '최근 노트';
  static const String sidebarLocked = '잠긴 노트';
  static const String sidebarHidden = '숨겨진 노트';
  static const String sidebarTrash = '휴지통';
  static const String sidebarFolders = '폴더';

  // 버튼 텍스트
  static const String buttonNew = '새 노트';
  static const String buttonDelete = '삭제';
  static const String buttonCancel = '취소';
  static const String buttonConfirm = '확인';
  static const String buttonSave = '저장';
  static const String buttonEdit = '수정';
  static const String buttonCreate = '만들기';
  static const String buttonClose = '닫기';
  static const String buttonRestore = '복원';
  static const String buttonMove = '이동';

  // 다이얼로그
  static const String dialogConfirmDelete = '삭제하시겠습니까?';
  static const String dialogMoveToTrash = '휴지통으로 이동했습니다';
  static const String dialogDeletePermanent = '30일 후 자동 삭제';
  static const String dialogSelectFormat = '내보내기 형식 선택';

  // 메시지
  static const String messageEmptyNotes = '새 노트를 만들어보세요';
  static const String messageEmptyNotesHint = '오른쪽 아래의 버튼을 눌러 시작하세요.';
  static const String messageSaving = '저장 중...';
  static const String messageNoFolder = '폴더 없음';
  static const String messageSelected = '개 선택됨';
}

// ==================== 애니메이션 상수 ====================
class AppAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // 사이드바 애니메이션
  static const Duration sidebarToggleDuration = Duration(milliseconds: 300);

  // 자동 저장 지연
  static const Duration autoSaveDuration = Duration(seconds: 1);

  // 컨텐츠 뷰 전환
  static const Duration contentSwitchDuration = Duration(milliseconds: 300);
}

// ==================== 네트워크 상수 ====================
class AppNetworkConfig {
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetryCount = 3;
}

// ==================== 저장소 상수 ====================
class AppStorageConfig {
  // 저장 공간 (MB)
  static const double totalStorageMB = 128.0 * 1024; // 128GB
  static const double freeStorageMB = 64.0 * 1024;   // 64GB

  // 휴지통 아이템 보관 기간 (일)
  static const int trashRetentionDays = 30;
}
