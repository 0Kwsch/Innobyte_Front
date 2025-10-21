// notes_home.dart 파일 내용 /.ㅇd

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 외부 파일에서 모델과 위젯을 가져옵니다.
import 'models.dart';
import 'note_widgets.dart';

// ====================================================
// 노트 홈페이지 위젯
// ====================================================

/// 노트 홈페이지 위젯 - 노트 목록과 편집 화면을 담당
class NotesHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme; // 테마 전환 콜백 함수
  final ThemeMode currentTheme; // 현재 테마 모드

  const NotesHomePage({
    super.key,
    required this.onToggleTheme,
    required this.currentTheme,
  });

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

/// 노트 홈페이지의 상태를 관리하는 클래스
class _NotesHomePageState extends State<NotesHomePage>
    with SingleTickerProviderStateMixin {
  // ==================== UI 상태 변수들 ====================
  int selectedMenuIndex = 0;
  String? selectedFolderName;
  Note? selectedNote;
  Note? hoveredNote;
  bool isEditMode = false;
  bool isSelectionMode = false;
  bool isSidebarCollapsed = false;
  final Set<Note> selectedNotes = {};

  // ==================== 뷰 설정 변수들 ====================
  ViewMode viewMode = ViewMode.grid;
  SortMode sortMode = SortMode.modifiedDate;
  String searchQuery = '';
  bool isAutoSaving = false;

  // ==================== 애니메이션 컨트롤러 ====================
  late AnimationController _animationController;

  // ==================== 데이터 리스트 ====================
  final List<Note> notes = [];
  final List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _createNewNote() {
    final newNote = Note(
      title: _getNewNoteTitle(),
      content: '내용을 입력하세요.',
      date: DateTime.now(),
      folderName: selectedFolderName,
    );
    setState(() {
      notes.insert(0, newNote);
      selectedNote = newNote;
      isEditMode = true;
    });
  }

  void _toggleStar(Note note) {
    setState(() {
      note.isStarred = !note.isStarred;
      _autoSave();
    });
  }

  void _deleteSelectedNotes() {
    setState(() {
      for (var note in selectedNotes) {
        note.isInTrash = true;
      }
      selectedNotes.clear();
      isSelectionMode = false;
    });
  }

  void _permanentlyDeleteSelectedNotes() {
    setState(() {
      notes.removeWhere((note) => selectedNotes.contains(note));
      selectedNotes.clear();
      isSelectionMode = false;
    });
  }

  void _restoreSelectedNotes() {
    setState(() {
      for (var note in selectedNotes) {
        note.isInTrash = false;
      }
      selectedNotes.clear();
      isSelectionMode = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedNotes.clear();
      }
    });
  }

  void _onNoteCardTap(Note note) {
    setState(() {
      if (isSelectionMode) {
        if (selectedNotes.contains(note)) {
          selectedNotes.remove(note);
        } else {
          selectedNotes.add(note);
        }
      } else {
        selectedNote = note;
        isEditMode = true;
      }
    });
  }

  void _autoSave() {
    setState(() {
      isAutoSaving = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isAutoSaving = false;
        });
      }
    });
  }

  List<Note> get _filteredNotes {
    List<Note> filteredList;

    if (selectedMenuIndex == 3) {
      filteredList = notes.where((note) => note.isInTrash).toList();
    } else if (selectedMenuIndex == 4) {
      filteredList = notes
          .where((note) => note.isLocked && !note.isInTrash)
          .toList();
    } else if (selectedMenuIndex == 5) {
      filteredList = notes
          .where((note) => note.isHidden && !note.isInTrash)
          .toList();
    } else {
      filteredList = notes
          .where((note) => !note.isInTrash && !note.isLocked && !note.isHidden)
          .toList();

      if (selectedFolderName != null) {
        filteredList = filteredList
            .where((note) => note.folderName == selectedFolderName)
            .toList();
      }

      if (selectedMenuIndex != -1) {
        switch (selectedMenuIndex) {
          case 0:
            break;
          case 1:
            filteredList = filteredList
                .where((note) => note.isStarred)
                .toList();
            break;
          case 2:
            filteredList = filteredList
                .where(
                  (note) => note.date.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
                .toList();
            break;
        }
      }
    }

    if (searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where(
            (note) =>
        note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(searchQuery.toLowerCase()),
      )
          .toList();
    }

    switch (sortMode) {
      case SortMode.modifiedDate:
        filteredList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortMode.createdDate:
        filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case SortMode.name:
        filteredList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.starred:
        filteredList.sort((a, b) {
          if (a.isStarred && !b.isStarred) return -1;
          if (!a.isStarred && b.isStarred) return 1;
          return b.date.compareTo(a.date);
        });
        break;
    }

    return filteredList;
  }

  void _onSidebarMenuTapped(int index) {
    setState(() {
      selectedMenuIndex = index;
      selectedFolderName = null;
    });
  }

  void _showQuickPreview(Note note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (note.imageUrl != null)
                Text(note.imageUrl!, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              Expanded(child: SingleChildScrollView(child: Text(note.content))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${note.date.year}-${note.date.month}-${note.date.day}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        _createNewNote,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          // 검색 포커스 기능
        },
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (selectedNotes.isNotEmpty) _deleteSelectedNotes();
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: !isEditMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            if (isEditMode) {
              setState(() {
                isEditMode = false;
                selectedNote = null;
              });
            }
          },
          child: Scaffold(
            body: isEditMode && selectedNote != null
                ? DrawingEditor(
              note: selectedNote!,
              onBack: () {
                setState(() {
                  isEditMode = false;
                  selectedNote = null;
                });
              },
              onSave: _autoSave,
            )
                : _buildGridScreen(),
            floatingActionButton: !isEditMode && !isSelectionMode
                ? FloatingActionButton(
              onPressed: _createNewNote,
              backgroundColor: const Color(0xFF678AFB),
              child: const Icon(Icons.edit_note, size: 30),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildGridScreen() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSidebarCollapsed ? 70 : 280,
          child: _buildSidebar(),
        ),
        Expanded(
          child: Column(
            children: [
              if (isSelectionMode)
                selectedMenuIndex == 3
                    ? _buildTrashSelectionHeader()
                    : _buildSelectionHeader()
              else if (selectedMenuIndex == 3)
                _buildTrashHeader()
              else
                _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContentView(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentView() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '새 노트를 만들어보세요',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 아래의 버튼을 눌러 시작하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    switch (viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.timeline:
        return _buildTimelineView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(
            2,
            6,
          );
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return NoteCard(
                note: note,
                isHovered: hoveredNote == note,
                isSelected: selectedNotes.contains(note),
                isSelectionMode: isSelectionMode,
                onTap: () => _onNoteCardTap(note),
                onLongPress: isSelectionMode ? null : _toggleSelectionMode,
                onHover: (isHovering) =>
                    setState(() => hoveredNote = isHovering ? note : null),
                onToggleStar: () => _toggleStar(note),
                onQuickPreview: () => _showQuickPreview(note),
                onMoreOptions: () => _showNoteContextMenu(note),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  note.imageUrl ?? '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.date.year}-${note.date.month}-${note.date.day}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    note.isStarred ? Icons.star : Icons.star_border,
                    color: note.isStarred ? Colors.amber : Colors.grey,
                    size: 24,
                  ),
                  onPressed: () => _toggleStar(note),
                ),
                if (note.tags.isNotEmpty)
                  const Icon(Icons.label, color: Colors.blue, size: 20),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNoteContextMenu(note),
                ),
              ],
            ),
            onTap: () => _onNoteCardTap(note),
          ),
        );
      },
    );
  }

  Widget _buildTimelineView() {
    final groupedNotes = <String, List<Note>>{};
    for (var note in _filteredNotes) {
      final dateKey = '${note.date.year}-${note.date.month}-${note.date.day}';
      groupedNotes.putIfAbsent(dateKey, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedNotes.length,
      itemBuilder: (context, index) {
        final dateKey = groupedNotes.keys.elementAt(index);
        final notesForDate = groupedNotes[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...notesForDate.map(
                  (note) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content, maxLines: 1),
                  onTap: () => _onNoteCardTap(note),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNoteContextMenu(Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                note.isStarred ? Icons.star : Icons.star_border,
                color: note.isStarred ? Colors.amber : null,
              ),
              title: Text(note.isStarred ? '즐겨찾기 해제' : '즐겨찾기 추가'),
              subtitle: const Text('빠른 접근을 위해 즐겨찾기'),
              onTap: () {
                Navigator.pop(context);
                _toggleStar(note);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                note.isLocked ? Icons.lock_open : Icons.lock,
                color: note.isLocked ? Colors.orange : null,
              ),
              title: Text(note.isLocked ? '잠금 해제' : '노트 잠금'),
              subtitle: const Text('중요한 노트 보호하기'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isLocked = !note.isLocked;
                  if (note.isLocked) note.isHidden = false;
                });
                _autoSave();
              },
            ),
            ListTile(
              leading: Icon(
                note.isHidden ? Icons.visibility : Icons.visibility_off,
                color: note.isHidden ? Colors.blue : null,
              ),
              title: Text(note.isHidden ? '숨기기 취소' : '노트 숨기기'),
              subtitle: const Text('목록에서 숨기기'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isHidden = !note.isHidden;
                  if (note.isHidden) note.isLocked = false;
                });
                _autoSave();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text('폴더로 이동'),
              subtitle: Text(note.folderName ?? '폴더 없음'),
              onTap: () {
                Navigator.pop(context);
                _showMoveToFolderDialog({note});
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.teal),
              title: const Text('복사본 생성'),
              subtitle: const Text('이 노트의 사본 만들기'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('공유'),
              subtitle: const Text('다른 사람과 공유하기'),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.indigo),
              title: const Text('내보내기'),
              subtitle: const Text('PDF, 텍스트 등으로 내보내기'),
              onTap: () {
                Navigator.pop(context);
                _exportSingleNote(note);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('휴지통으로 이동'),
              subtitle: const Text('30일 후 자동 삭제'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isInTrash = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${note.title}을(를) 휴지통으로 이동했습니다'),
                    action: SnackBarAction(
                      label: '취소',
                      onPressed: () {
                        setState(() {
                          note.isInTrash = false;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateNote(Note originalNote) {
    final duplicatedNote = Note(
      title: '${originalNote.title} (사본)',
      content: originalNote.content,
      date: DateTime.now(),
      folderName: originalNote.folderName,
      tags: List.from(originalNote.tags),
      strokes: List.from(originalNote.strokes),
      imageUrl: originalNote.imageUrl,
    );
    setState(() {
      notes.insert(notes.indexOf(originalNote) + 1, duplicatedNote);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${originalNote.title}의 복사본을 생성했습니다')),
    );
  }

  void _exportSingleNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내보내기 형식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) PDF로 내보내는 중...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('텍스트 파일'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) 텍스트로 내보내는 중...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('이미지'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) 이미지로 내보내는 중...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveToFolderDialog(Set<Note> notesToMove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${notesToMove.length}개의 노트를 폴더로 이동'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('없음 (폴더에서 제거)'),
                onTap: () {
                  setState(() {
                    for (var note in notesToMove) {
                      note.folderName = null;
                    }
                    isSelectionMode = false;
                    selectedNotes.clear();
                  });
                  Navigator.pop(context);
                },
              ),
              ...folders.map(
                    (folder) => ListTile(
                  title: Text(folder.name),
                  onTap: () {
                    setState(() {
                      for (var note in notesToMove) {
                        note.folderName = folder.name;
                      }
                      isSelectionMode = false;
                      selectedNotes.clear();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareNote(Note note) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${note.title} 공유하기')));
  }

  Widget _buildSidebar() {
    if (isSidebarCollapsed) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3E3E3E)
            : const Color(0xFF3E3E3E),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSidebarCollapsed = false;
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3E3E3E)
            : const Color(0xFF3E3E3E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSidebarHeader(),
            _buildSidebarSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSidebarItem(
                      Icons.all_inbox,
                      '모든 노트',
                      notes.where((n) => !n.isInTrash).length,
                      0,
                    ),
                    _buildSidebarItem(
                      Icons.star_border,
                      '즐겨찾기',
                      notes.where((n) => n.isStarred && !n.isInTrash).length,
                      1,
                    ),
                    _buildSidebarItem(
                      Icons.access_time,
                      '최근 노트',
                      notes.where((n) => !n.isInTrash).take(5).length,
                      2,
                    ),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildSidebarItem(
                      Icons.lock_outline,
                      '잠긴 노트',
                      notes.where((n) => n.isLocked && !n.isInTrash).length,
                      4,
                    ),
                    _buildSidebarItem(
                      Icons.visibility_off_outlined,
                      '숨겨진 노트',
                      notes.where((n) => n.isHidden && !n.isInTrash).length,
                      5,
                    ),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildFolderSection(),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildSidebarItem(
                      Icons.delete_outline,
                      '휴지통',
                      notes.where((n) => n.isInTrash).length,
                      3,
                    ),
                  ],
                ),
              ),
            ),
            _buildSidebarFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF678AFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.note_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Samsung Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'new_note':
                  _createNewNote();
                  break;
                case 'new_folder':
                  _showCreateFolderDialog();
                  break;
                case 'collapse':
                  setState(() {
                    isSidebarCollapsed = true;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_note', child: Text('새 노트')),
              const PopupMenuItem(value: 'new_folder', child: Text('새 폴더')),
              const PopupMenuItem(value: 'collapse', child: Text('사이드바 접기')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '노트 검색...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSettingsDialog,
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    '설정',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (isAutoSaving) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[400]!,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '저장 중...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, double>> _getStorageInfo() async {
    return {'total': 128.0 * 1024, 'free': 64.0 * 1024};
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        title: const Text('설정'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              FutureBuilder<Map<String, double>>(
                future: _getStorageInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const ListTile(title: Text('저장 공간 정보를 불러올 수 없습니다.'));
                  }

                  final totalSpaceMB = snapshot.data!['total']!;
                  final freeSpaceMB = snapshot.data!['free']!;
                  final usedSpaceMB = totalSpaceMB - freeSpaceMB;
                  final usedPercentage = totalSpaceMB > 0
                      ? usedSpaceMB / totalSpaceMB
                      : 0.0;

                  final totalSpaceGB = (totalSpaceMB / 1024).toStringAsFixed(1);
                  final usedSpaceGB = (usedSpaceMB / 1024).toStringAsFixed(1);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '저장 공간',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$usedSpaceGB GB / $totalSpaceGB GB 사용 중',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usedPercentage,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF678AFB),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('잠금 설정'),
                subtitle: const Text('생체 인증으로 노트 보호'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('언어'),
                subtitle: const Text('한국어'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('기본 글꼴'),
                subtitle: const Text('시스템 기본'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알림'),
                subtitle: const Text('알림 설정 관리'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('정보'),
                subtitle: const Text('버전 1.0.0'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('도움말'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                onTap: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int count, int index) {
    final isSelected = selectedMenuIndex == index;
    return InkWell(
      onTap: () => _onSidebarMenuTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A5A5A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF678AFB) : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.folder, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                '폴더',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showCreateFolderDialog,
                child: const Icon(Icons.add, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ),
        ...folders.map((folder) => _buildFolderTile(folder)),
      ],
    );
  }

  Widget _buildFolderTile(Folder folder) {
    final isSelected = selectedFolderName == folder.name;
    final folderNoteCount = notes
        .where((n) => n.folderName == folder.name && !n.isInTrash)
        .length;

    return InkWell(
      onTap: () {
        setState(() {
          selectedFolderName = folder.name;
          selectedMenuIndex = -1;
        });
      },
      onLongPress: () => _showFolderOptionsMenu(folder),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A5A5A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, color: folder.color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (folderNoteCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? folder.color : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  folderNoteCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFolderOptionsMenu(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(context);
                _renameFolderDialog(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('색상 변경'),
              onTap: () {
                Navigator.pop(context);
                _changeFolderColor(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFolderDialog(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeFolderColor(Folder folder) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 색상 선택'),
        content: Wrap(
          spacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                setState(() {
                  folder.color = color;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: folder.color == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _renameFolderDialog(Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이름 변경'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  folder.name = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 만들기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '폴더 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  folders.add(Folder(name: controller.text, count: 0));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  void _deleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                folders.remove(folder);
                if (selectedFolderName == folder.name) {
                  selectedFolderName = null;
                  selectedMenuIndex = 0;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = '모든 노트';
    if (selectedFolderName != null) {
      title = selectedFolderName!;
    } else {
      switch (selectedMenuIndex) {
        case 1:
          title = '즐겨찾기';
          break;
        case 2:
          title = '최근 노트';
          break;
        case 4:
          title = '잠긴 노트';
          break;
        case 5:
          title = '숨겨진 노트';
          break;
      }
    }

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filteredNotes.length.toString(),
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(width: 20),
          PopupMenuButton<SortMode>(
            icon: Row(
              children: [
                const Icon(Icons.sort, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  _getSortModeText(sortMode),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            onSelected: (mode) {
              setState(() {
                sortMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortMode.modifiedDate,
                child: Text('최근 수정일'),
              ),
              const PopupMenuItem(
                value: SortMode.createdDate,
                child: Text('생성일'),
              ),
              const PopupMenuItem(value: SortMode.name, child: Text('이름')),
              const PopupMenuItem(
                value: SortMode.starred,
                child: Text('즐겨찾기 우선'),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  viewMode == ViewMode.grid
                      ? Icons.grid_view
                      : viewMode == ViewMode.list
                      ? Icons.view_list
                      : Icons.timeline,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    viewMode = ViewMode
                        .values[(viewMode.index + 1) % ViewMode.values.length];
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.select_all),
                            title: const Text('모두 선택'),
                            onTap: () {
                              Navigator.pop(context);
                              _toggleSelectionMode();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.download),
                            title: const Text('내보내기'),
                            onTap: () {
                              Navigator.pop(context);
                              _exportNotes();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortModeText(SortMode mode) {
    switch (mode) {
      case SortMode.modifiedDate:
        return '최근 수정일';
      case SortMode.createdDate:
        return '생성일';
      case SortMode.name:
        return '이름순';
      case SortMode.starred:
        return '즐겨찾기';
    }
  }

  void _exportNotes() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('노트를 내보내는 중...')));
  }

  Widget _buildSelectionHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSelectionMode,
          ),
          Text(
            '${selectedNotes.length}개 선택됨',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: () {
              if (selectedNotes.isNotEmpty) {
                _showMoveToFolderDialog(selectedNotes);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: selectedNotes.isNotEmpty ? _deleteSelectedNotes : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTrashHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Text(
            '휴지통',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filteredNotes.length.toString(),
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                notes.removeWhere((note) => note.isInTrash);
              });
            },
            child: const Text('모두 비우기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashSelectionHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSelectionMode,
          ),
          Text(
            '${selectedNotes.length}개 선택됨',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Spacer(),
          TextButton(
            onPressed: _restoreSelectedNotes,
            child: const Text('복원', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.white,
            ),
            onPressed: _permanentlyDeleteSelectedNotes,
          ),
        ],
      ),
    );
  }
}