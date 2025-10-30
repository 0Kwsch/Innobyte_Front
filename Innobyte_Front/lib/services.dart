// services.dart
// 노트 관리 및 필터링 로직을 담당하는 서비스 클래스

import 'package:flutter/material.dart';
import 'models.dart';

/// 노트 관리 서비스
/// 노트의 CRUD 작업, 필터링, 정렬 등의 비즈니스 로직을 담당합니다
class NoteManagementService {
  // ==================== 노트 목록 ====================
  final List<Note> notes = [];
  final List<Folder> folders = [];

  // ==================== 생성자 ====================
  NoteManagementService();

  // ==================== 노트 생성 ====================
  /// 새 노트 생성
  /// 중복된 제목이 없도록 처리합니다
  Note createNewNote({
    String? folderName,
  }) {
    final newNote = Note(
      title: _getNewNoteTitle(),
      content: '내용을 입력하세요.',
      date: DateTime.now(),
      folderName: folderName,
    );
    notes.insert(0, newNote);
    return newNote;
  }

  /// 새로운 노트 제목 생성
  /// "새 노트 1", "새 노트 2" ... 형식
  String _getNewNoteTitle() {
    int counter = 1;
    String newTitle;
    final existingTitles = notes.map((note) => note.title).toSet();

    while (true) {
      newTitle = '새 노트 $counter';
      if (!existingTitles.contains(newTitle)) {
        return newTitle;
      }
      counter++;
    }
  }

  // ==================== 노트 수정 ====================
  /// 노트 즐겨찾기 토글
  void toggleStar(Note note) {
    note.isStarred = !note.isStarred;
  }

  /// 노트 잠금 토글
  void toggleLock(Note note) {
    note.isLocked = !note.isLocked;
    // 잠금 상태가 되면 숨김 취소
    if (note.isLocked) {
      note.isHidden = false;
    }
  }

  /// 노트 숨김 토글
  void toggleHidden(Note note) {
    note.isHidden = !note.isHidden;
    // 숨김 상태가 되면 잠금 취소
    if (note.isHidden) {
      note.isLocked = false;
    }
  }

  /// 노트를 폴더로 이동
  void moveNoteToFolder(Note note, String? folderName) {
    note.folderName = folderName;
  }

  // ==================== 노트 삭제 ====================
  /// 여러 노트를 휴지통으로 이동
  void moveNotesToTrash(Set<Note> notesToMove) {
    for (var note in notesToMove) {
      note.isInTrash = true;
    }
  }

  /// 여러 노트를 휴지통에서 복원
  void restoreMultipleFromTrash(Set<Note> notesToRestore) {
    for (var note in notesToRestore) {
      note.isInTrash = false;
    }
  }

  /// 여러 노트 영구 삭제
  void deleteNotesPermanently(Set<Note> notesToDelete) {
    notes.removeWhere((note) => notesToDelete.contains(note));
  }

  /// 휴지통 비우기
  void emptyTrash() {
    notes.removeWhere((note) => note.isInTrash);
  }

  // ==================== 노트 복제 ====================
  /// 노트 복제
  Note duplicateNote(Note originalNote) {
    final duplicatedNote = Note(
      title: '${originalNote.title} (사본)',
      content: originalNote.content,
      date: DateTime.now(),
      folderName: originalNote.folderName,
      tags: List.from(originalNote.tags),
      strokes: List.from(originalNote.strokes),
      imageUrl: originalNote.imageUrl,
    );
    notes.insert(notes.indexOf(originalNote) + 1, duplicatedNote);
    return duplicatedNote;
  }

  // ==================== 필터링 및 정렬 ====================
  /// 노트 필터링 및 정렬
  /// [menuIndex]: 선택된 메뉴 인덱스
  /// [folderName]: 선택된 폴더 이름
  /// [searchQuery]: 검색어
  /// [sortMode]: 정렬 방식
  List<Note> getFilteredAndSortedNotes({
    required int menuIndex,
    String? folderName,
    required String searchQuery,
    required SortMode sortMode,
  }) {
    List<Note> filteredList = _filterNotesByMenu(menuIndex, folderName);
    filteredList = _filterNotesBySearch(filteredList, searchQuery);
    filteredList = _sortNotes(filteredList, sortMode);
    return filteredList;
  }

  /// 메뉴 선택에 따른 필터링
  /// - 0: 모든 노트
  /// - 1: 즐겨찾기
  /// - 2: 최근 노트 (7일 이내)
  /// - 3: 휴지통
  /// - 4: 잠긴 노트
  /// - 5: 숨겨진 노트
  List<Note> _filterNotesByMenu(int menuIndex, String? folderName) {
    List<Note> filteredList;

    if (menuIndex == 3) {
      // 휴지통
      filteredList = notes.where((note) => note.isInTrash).toList();
    } else if (menuIndex == 4) {
      // 잠긴 노트
      filteredList = notes
          .where((note) => note.isLocked && !note.isInTrash)
          .toList();
    } else if (menuIndex == 5) {
      // 숨겨진 노트
      filteredList = notes
          .where((note) => note.isHidden && !note.isInTrash)
          .toList();
    } else {
      // 일반 노트 (휴지통, 잠금, 숨김 제외)
      filteredList = notes
          .where((note) => !note.isInTrash && !note.isLocked && !note.isHidden)
          .toList();

      // 폴더 필터링
      if (folderName != null) {
        filteredList = filteredList
            .where((note) => note.folderName == folderName)
            .toList();
      }

      // 메뉴별 필터링
      if (menuIndex == 1) {
        // 즐겨찾기
        filteredList = filteredList
            .where((note) => note.isStarred)
            .toList();
      } else if (menuIndex == 2) {
        // 최근 노트 (7일 이내)
        filteredList = filteredList
            .where(
              (note) => note.date.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
            .toList();
      }
    }

    return filteredList;
  }

  /// 검색어를 통한 필터링
  /// 제목과 내용에서 검색 (대소문자 무시)
  List<Note> _filterNotesBySearch(List<Note> notes, String searchQuery) {
    if (searchQuery.isEmpty) {
      return notes;
    }

    return notes
        .where(
          (note) =>
      note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(searchQuery.toLowerCase()),
    )
        .toList();
  }

  /// 정렬 방식 적용
  List<Note> _sortNotes(List<Note> notes, SortMode sortMode) {
    final sortedList = List<Note>.from(notes);

    switch (sortMode) {
      case SortMode.modifiedDate:
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortMode.createdDate:
        sortedList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case SortMode.name:
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.starred:
        sortedList.sort((a, b) {
          if (a.isStarred && !b.isStarred) return -1;
          if (!a.isStarred && b.isStarred) return 1;
          return b.date.compareTo(a.date);
        });
        break;
    }

    return sortedList;
  }

  // ==================== 폴더 관리 ====================
  /// 새 폴더 생성
  Folder createFolder(String name) {
    final folder = Folder(name: name, count: 0);
    folders.add(folder);
    return folder;
  }

  /// 폴더 이름 변경
  void renameFolder(Folder folder, String newName) {
    if (newName.isNotEmpty) {
      folder.name = newName;
    }
  }

  /// 폴더 삭제
  void deleteFolder(Folder folder) {
    // 폴더 내의 모든 노트의 폴더명 제거
    for (var note in notes) {
      if (note.folderName == folder.name) {
        note.folderName = null;
      }
    }
    folders.remove(folder);
  }

  /// 폴더 색상 변경
  void changeFolderColor(Folder folder, Color color) {
    folder.color = color;
  }
}

/// 정렬 모드 (models.dart에서 정의됨)
/// 여기서는 NoteManagementService에서만 사용
