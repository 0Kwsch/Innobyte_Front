// models.dart 파일 내용 /.ㅇ>

import 'package:flutter/material.dart';

// ====================================================
// 1. 데이터 모델 및 열거형
// ====================================================

/// 뷰 모드 열거형
enum ViewMode { grid, list, timeline }

/// 정렬 모드 열거형
enum SortMode { modifiedDate, createdDate, name, starred }

/// 그리기 도구 열거형
enum DrawingTool { pen, pencil, highlighter, eraser, lasso }

/// 노트 클래스
class Note {
  String title;
  String content;
  DateTime date;
  DateTime createdDate;
  bool isStarred;
  bool isInTrash;
  bool isLocked;
  bool isHidden;
  String? imageUrl;
  String? folderName;
  List<String> tags;
  List<DrawingStroke> strokes;

  Note({
    required this.title,
    required this.content,
    required this.date,
    DateTime? createdDate,
    this.isInTrash = false,
    this.isStarred = false,
    this.isLocked = false,
    this.isHidden = false,
    this.imageUrl,
    this.folderName,
    this.tags = const [],
    this.strokes = const [],
  }) : createdDate = createdDate ?? date;
}

/// 그리기 스트로크 클래스
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final DrawingTool tool;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });
}

/// 폴더 클래스
class Folder {
  String name;
  final int count;
  final List<Folder> subfolders;
  Color color;

  Folder({
    required this.name,
    required this.count,
    this.subfolders = const [],
    this.color = const Color(0xFF678AFB),
  });
}