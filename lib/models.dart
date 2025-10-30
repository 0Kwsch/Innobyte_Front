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
  List<PDFFile> attachedPdfs;  // 첨부된 PDF 파일들

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
    this.attachedPdfs = const [],
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

/// PDF 파일 클래스
class PDFFile {
  final String name;           // PDF 파일명
  final String path;           // 파일 경로
  final DateTime addedDate;    // 추가된 날짜
  final double fileSize;       // 파일 크기 (MB)

  PDFFile({
    required this.name,
    required this.path,
    DateTime? addedDate,
    required this.fileSize,
  }) : addedDate = addedDate ?? DateTime.now();
}