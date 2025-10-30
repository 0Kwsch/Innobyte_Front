// screens/notes_screen.dart
// 노트 홈 페이지 메인 화면
// 사이드바, 헤더, 콘텐츠를 조합한 전체 레이아웃입니다

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../constants.dart';
import '../models.dart';
import '../services.dart';
import '../note_widgets.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/content_view.dart';
import '../widgets/dialogs.dart';

/// 노트 홈 페이지 위젯
class NotesHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode currentTheme;

  const NotesHomePage({
    super.key,
    required this.onToggleTheme,
    required this.currentTheme,
  });

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

/// 노트 홈 페이지 상태 관리
class _NotesHomePageState extends State<NotesHomePage>
    with SingleTickerProviderStateMixin {
  // ==================== 서비스 ====================
  late NoteManagementService noteService;

  // ==================== UI 상태 ====================
  int selectedMenuIndex = 0;
  String? selectedFolderName;
  Note? selectedNote;
  Note? hoveredNote;
  bool isEditMode = false;
  bool isSelectionMode = false;
  bool isSidebarCollapsed = false;
  final Set<Note> selectedNotes = {};

  // ==================== 뷰 설정 ====================
  ViewMode viewMode = ViewMode.grid;
  SortMode sortMode = SortMode.modifiedDate;
  String searchQuery = '';
  bool isAutoSaving = false;

  // ==================== 애니메이션 ====================
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    noteService = NoteManagementService();
    animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.mediumDuration,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  // ==================== 필터링된 노트 ====================
  List<Note> get filteredNotes {
    return noteService.getFilteredAndSortedNotes(
      menuIndex: selectedMenuIndex,
      folderName: selectedFolderName,
      searchQuery: searchQuery,
      sortMode: sortMode,
    );
  }

  // ==================== 노트 CRUD 작업 ====================
  void _createNewNote() {
    final newNote = noteService.createNewNote(
      folderName: selectedFolderName,
    );
    setState(() {
      selectedNote = newNote;
      isEditMode = true;
    });
  }

  void _toggleStar(Note note) {
    setState(() {
      noteService.toggleStar(note);
      _autoSave();
    });
  }

  void _deleteSelectedNotes() {
    noteService.moveNotesToTrash(selectedNotes);
    setState(() {
      selectedNotes.clear();
      isSelectionMode = false;
    });
  }

  void _permanentlyDeleteSelectedNotes() {
    noteService.deleteNotesPermanently(selectedNotes);
    setState(() {
      selectedNotes.clear();
      isSelectionMode = false;
    });
  }

  void _restoreSelectedNotes() {
    noteService.restoreMultipleFromTrash(selectedNotes);
    setState(() {
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

  void _duplicateNote(Note note) {
    noteService.duplicateNote(note);
    setState(() {});
    _showSnackbar('${note.title}의 복사본을 생성했습니다');
  }

  // ==================== 폴더 관리 ====================
  void _createFolder(String folderName) {
    if (folderName.isNotEmpty) {
      noteService.createFolder(folderName);
      setState(() {});
    }
  }

  void _renameFolder(Folder folder, String newName) {
    if (newName.isNotEmpty) {
      noteService.renameFolder(folder, newName);
      setState(() {});
    }
  }

  void _deleteFolder(Folder folder) {
    noteService.deleteFolder(folder);
    setState(() {
      if (selectedFolderName == folder.name) {
        selectedFolderName = null;
        selectedMenuIndex = 0;
      }
    });
  }

  void _changeFolderColor(Folder folder, Color color) {
    noteService.changeFolderColor(folder, color);
    setState(() {});
  }

  // ==================== 유틸리티 ====================
  void _autoSave() {
    setState(() {
      isAutoSaving = true;
    });
    Future.delayed(AppAnimations.autoSaveDuration, () {
      if (mounted) {
        setState(() {
          isAutoSaving = false;
        });
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ==================== 다이얼로그 표시 ====================
  void _showQuickPreview(Note note) {
    showDialog(
      context: context,
      builder: (context) => QuickPreviewDialog(
        note: note,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showNoteContextMenu(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NoteContextMenu(
        note: note,
        onToggleStar: () {
          setState(() {
            noteService.toggleStar(note);
            _autoSave();
          });
        },
        onToggleLock: () {
          setState(() {
            noteService.toggleLock(note);
            _autoSave();
          });
        },
        onToggleHidden: () {
          setState(() {
            noteService.toggleHidden(note);
            _autoSave();
          });
        },
        onMoveToFolder: () => _showMoveToFolderDialog({note}),
        onDuplicate: () => _duplicateNote(note),
        onShare: () => _shareNote(note),
        onExport: () => _exportSingleNote(note),
        onDelete: () {
          setState(() {
            noteService.moveNotesToTrash({note});
          });
          _showSnackbar('${note.title}을(를) 휴지통으로 이동했습니다');
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showMoveToFolderDialog(Set<Note> notesToMove) {
    showDialog(
      context: context,
      builder: (context) => MoveToFolderDialog(
        noteCount: notesToMove.length,
        folders: noteService.folders,
        onNoFolder: () {
          setState(() {
            for (var note in notesToMove) {
              noteService.moveNoteToFolder(note, null);
            }
          });
        },
        onFolderSelected: (folder) {
          setState(() {
            for (var note in notesToMove) {
              noteService.moveNoteToFolder(note, folder.name);
            }
          });
        },
        onCancel: () {},
      ),
    );
  }

  void _showFolderOptionsMenu(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FolderOptionsMenu(
        folder: folder,
        onRename: () => _showRenameFolderDialog(folder),
        onChangeColor: () => _showChangeFolderColorDialog(folder),
        onDelete: () => _showDeleteFolderDialog(folder),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => RenameFolderDialog(
        folder: folder,
        onConfirm: () => _renameFolder(folder, folder.name),
        onCancel: () {},
      ),
    );
  }

  void _showChangeFolderColorDialog(Folder folder) {
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
                _changeFolderColor(folder, color);
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

  void _showDeleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.buttonCancel),
          ),
          TextButton(
            onPressed: () {
              _deleteFolder(folder);
              Navigator.pop(context);
            },
            child: const Text(
              AppText.buttonDelete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        onConfirm: () => _createFolder(controller.text),
        onCancel: () {},
      ),
    );
  }

  void _shareNote(Note note) {
    _showSnackbar('${note.title} 공유하기');
  }

  void _exportSingleNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => ExportFormatDialog(
        noteTitle: note.title,
        onPDF: () => _showSnackbar('${note.title}을(를) PDF로 내보내는 중...'),
        onText: () => _showSnackbar('${note.title}을(를) 텍스트로 내보내는 중...'),
        onImage: () => _showSnackbar('${note.title}을(를) 이미지로 내보내는 중...'),
        onCancel: () {},
      ),
    );
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
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('정보'),
                subtitle: const Text('버전 1.0.0'),
                onTap: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.buttonClose),
          ),
        ],
      ),
    );
  }

  void _showPDFPicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            final pdfFile = PDFFile(
              name: file.name,
              path: file.path!,
              fileSize: file.size / (1024 * 1024), // Convert to MB
            );

            // 선택된 노트에 PDF 추가
            if (selectedNote != null) {
              setState(() {
                selectedNote!.attachedPdfs = [
                  ...selectedNote!.attachedPdfs,
                  pdfFile,
                ];
              });
              _showSnackbar('${file.name}이(가) 추가되었습니다');
            } else {
              // 노트가 선택되지 않았으면 새 노트 생성 후 추가
              final newNote = noteService.createNewNote();
              setState(() {
                selectedNote = newNote;
                selectedNote!.attachedPdfs = [pdfFile];
              });
              _showSnackbar('새 노트에 ${file.name}이(가) 추가되었습니다');
            }
          }
        }
      }
    } catch (e) {
      _showSnackbar('PDF 파일을 선택할 수 없습니다: $e');
    }
  }

  void _showMoreOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
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
                _showSnackbar('노트를 내보내는 중...');
              },
            ),
          ],
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
                : _buildMainScreen(),
            floatingActionButton: !isEditMode && !isSelectionMode
                ? FloatingActionButton(
              onPressed: _createNewNote,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.edit_note, size: 30),
            )
                : null,
          ),
        ),
      ),
    );
  }

  /// 메인 화면 레이아웃
  Widget _buildMainScreen() {
    return Row(
      children: [
        // 사이드바
        AnimatedContainer(
          duration: AppAnimations.sidebarToggleDuration,
          width: isSidebarCollapsed
              ? AppSizes.sidebarCollapsedWidth
              : AppSizes.sidebarExpandedWidth,
          child: NotesSidebarWidget(
            selectedMenuIndex: selectedMenuIndex,
            selectedFolderName: selectedFolderName,
            folders: noteService.folders,
            notes: noteService.notes,
            isSidebarCollapsed: isSidebarCollapsed,
            isAutoSaving: isAutoSaving,
            onMenuTapped: (index) {
              setState(() {
                selectedMenuIndex = index;
                selectedFolderName = null;
              });
            },
            onFolderSelected: (folderName) {
              setState(() {
                selectedFolderName = folderName;
                selectedMenuIndex = -1;
              });
            },
            onToggleCollapse: () {
              setState(() {
                isSidebarCollapsed = !isSidebarCollapsed;
              });
            },
            onCreateNewNote: _createNewNote,
            onCreateFolder: _showCreateFolderDialog,
            onSettings: _showSettingsDialog,
            onFolderOptions: _showFolderOptionsMenu,
            onAddPDF: _showPDFPicker,
          ),
        ),
        // 메인 콘텐츠
        Expanded(
          child: Column(
            children: [
              // 헤더
              if (isSelectionMode)
                selectedMenuIndex == 3
                    ? NotesSelectionHeaderBar(
                  selectedCount: selectedNotes.length,
                  isTrashMode: true,
                  onClose: _toggleSelectionMode,
                  onRestore: _restoreSelectedNotes,
                  onPermanentDelete: _permanentlyDeleteSelectedNotes,
                )
                    : NotesSelectionHeaderBar(
                  selectedCount: selectedNotes.length,
                  isTrashMode: false,
                  onClose: _toggleSelectionMode,
                  onMoveFolder: () =>
                      _showMoveToFolderDialog(selectedNotes),
                  onDelete: _deleteSelectedNotes,
                )
              else if (selectedMenuIndex == 3)
                TrashHeaderBar(
                  trashNotesCount: filteredNotes.length,
                  onEmptyTrash: () {
                    noteService.emptyTrash();
                    setState(() {});
                  },
                )
              else
                NotesHeaderBar(
                  selectedMenuIndex: selectedMenuIndex,
                  selectedFolderName: selectedFolderName,
                  viewMode: viewMode,
                  sortMode: sortMode,
                  filteredNotesCount: filteredNotes.length,
                  onSortChanged: (mode) {
                    setState(() {
                      sortMode = mode;
                    });
                  },
                  onViewModeChanged: () {
                    setState(() {
                      viewMode = ViewMode.values[
                      (viewMode.index + 1) % ViewMode.values.length
                      ];
                    });
                  },
                  onMoreOptions: _showMoreOptionsMenu,
                ),
              // 콘텐츠 뷰
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppAnimations.contentSwitchDuration,
                  child: NotesContentView(
                    key: ValueKey(viewMode),
                    filteredNotes: filteredNotes,
                    viewMode: viewMode,
                    isSelectionMode: isSelectionMode,
                    selectedNotes: selectedNotes,
                    onNoteTap: _onNoteCardTap,
                    onToggleStar: _toggleStar,
                    onQuickPreview: _showQuickPreview,
                    onMoreOptions: _showNoteContextMenu,
                    onHover: (note, isHovering) {
                      setState(() {
                        hoveredNote = isHovering ? note : null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
