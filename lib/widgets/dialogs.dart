// dialogs.dart
// 다양한 다이얼로그 및 모달 위젯들
// 확인, 삭제, 이동, 옵션 선택 등의 다이얼로그를 제공합니다

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

/// 노트 삭제 확인 다이얼로그
class ConfirmDeleteDialog extends StatelessWidget {
  final int noteCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isPermanent;

  const ConfirmDeleteDialog({
    super.key,
    required this.noteCount,
    required this.onConfirm,
    required this.onCancel,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isPermanent ? '영구 삭제' : AppText.dialogConfirmDelete,
      ),
      content: Text(
        isPermanent
            ? '$noteCount개의 노트를 영구적으로 삭제하시겠습니까?\n삭제된 노트는 복구할 수 없습니다.'
            : '$noteCount개의 노트를 휴지통으로 이동하시겠습니까?',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(AppText.buttonCancel),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            AppText.buttonDelete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

/// 노트를 폴더로 이동하는 다이얼로그
class MoveToFolderDialog extends StatelessWidget {
  final int noteCount;
  final List<Folder> folders;
  final VoidCallback onNoFolder;
  final Function(Folder) onFolderSelected;
  final VoidCallback onCancel;

  const MoveToFolderDialog({
    super.key,
    required this.noteCount,
    required this.folders,
    required this.onNoFolder,
    required this.onFolderSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$noteCount개의 노트를 폴더로 이동'),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text(AppText.messageNoFolder),
              onTap: () {
                onNoFolder();
                Navigator.pop(context);
              },
            ),
            ...folders.map(
                  (folder) => ListTile(
                title: Text(folder.name),
                leading: Icon(Icons.folder, color: folder.color),
                onTap: () {
                  onFolderSelected(folder);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(AppText.buttonCancel),
        ),
      ],
    );
  }
}

/// 내보내기 형식 선택 다이얼로그
class ExportFormatDialog extends StatelessWidget {
  final String noteTitle;
  final VoidCallback onPDF;
  final VoidCallback onText;
  final VoidCallback onImage;
  final VoidCallback onCancel;

  const ExportFormatDialog({
    super.key,
    required this.noteTitle,
    required this.onPDF,
    required this.onText,
    required this.onImage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppText.dialogSelectFormat),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('PDF'),
            onTap: () {
              onPDF();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_snippet, color: Colors.blue),
            title: const Text('텍스트 파일'),
            onTap: () {
              onText();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.green),
            title: const Text('이미지'),
            onTap: () {
              onImage();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(AppText.buttonCancel),
        ),
      ],
    );
  }
}

/// 빠른 미리보기 다이얼로그
class QuickPreviewDialog extends StatelessWidget {
  final Note note;
  final VoidCallback onClose;

  const QuickPreviewDialog({
    super.key,
    required this.note,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 400,
        padding: const EdgeInsets.all(AppSizes.paddingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXXXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            if (note.imageUrl != null)
              Text(
                note.imageUrl!,
                style: const TextStyle(fontSize: 50),
              ),
            const SizedBox(height: AppSizes.paddingLarge),
            Expanded(
              child: SingleChildScrollView(
                child: Text(note.content),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: AppSizes.iconMedium,
                  color: Colors.grey[600],
                ),
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
    );
  }
}

/// 폴더 옵션 메뉴 (바텀 시트)
class FolderOptionsMenu extends StatelessWidget {
  final Folder folder;
  final VoidCallback onRename;
  final VoidCallback onChangeColor;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const FolderOptionsMenu({
    super.key,
    required this.folder,
    required this.onRename,
    required this.onChangeColor,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('이름 변경'),
            onTap: () {
              Navigator.pop(context);
              onRename();
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('색상 변경'),
            onTap: () {
              Navigator.pop(context);
              onChangeColor();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

/// 폴더 색상 선택 다이얼로그
class FolderColorPickerDialog extends StatelessWidget {
  final Folder folder;
  final VoidCallback onClose;

  const FolderColorPickerDialog({
    super.key,
    required this.folder,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return AlertDialog(
      title: const Text('폴더 색상 선택'),
      content: Wrap(
        spacing: 10,
        children: colors.map((color) {
          return InkWell(
            onTap: () {
              // 색상 변경은 부모에서 처리
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
    );
  }
}

/// 폴더 이름 변경 다이얼로그
class RenameFolderDialog extends StatefulWidget {
  final Folder folder;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const RenameFolderDialog({
    super.key,
    required this.folder,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<RenameFolderDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.folder.name);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('폴더 이름 변경'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '새 폴더 이름',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onCancel();
          },
          child: const Text(AppText.buttonCancel),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              widget.folder.name = controller.text;
              Navigator.pop(context);
              widget.onConfirm();
            }
          },
          child: const Text(AppText.buttonConfirm),
        ),
      ],
    );
  }
}

/// 새 폴더 생성 다이얼로그
class CreateFolderDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CreateFolderDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 폴더 만들기'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '폴더 이름'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onCancel();
          },
          child: const Text(AppText.buttonCancel),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              Navigator.pop(context);
              widget.onConfirm();
            }
          },
          child: const Text(AppText.buttonCreate),
        ),
      ],
    );
  }
}

/// 노트 컨텍스트 메뉴 (바텀 시트)
class NoteContextMenu extends StatelessWidget {
  final Note note;
  final VoidCallback onToggleStar;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleHidden;
  final VoidCallback onMoveToFolder;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const NoteContextMenu({
    super.key,
    required this.note,
    required this.onToggleStar,
    required this.onToggleLock,
    required this.onToggleHidden,
    required this.onMoveToFolder,
    required this.onDuplicate,
    required this.onShare,
    required this.onExport,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: SingleChildScrollView(
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
              title: Text(
                note.isStarred ? '즐겨찾기 해제' : '즐겨찾기 추가',
              ),
              subtitle: const Text('빠른 접근을 위해 즐겨찾기'),
              onTap: () {
                Navigator.pop(context);
                onToggleStar();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                note.isLocked ? Icons.lock_open : Icons.lock,
                color: note.isLocked ? Colors.orange : null,
              ),
              title: Text(
                note.isLocked ? '잠금 해제' : '노트 잠금',
              ),
              subtitle: const Text('중요한 노트 보호하기'),
              onTap: () {
                Navigator.pop(context);
                onToggleLock();
              },
            ),
            ListTile(
              leading: Icon(
                note.isHidden ? Icons.visibility : Icons.visibility_off,
                color: note.isHidden ? Colors.blue : null,
              ),
              title: Text(
                note.isHidden ? '숨기기 취소' : '노트 숨기기',
              ),
              subtitle: const Text('목록에서 숨기기'),
              onTap: () {
                Navigator.pop(context);
                onToggleHidden();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text('폴더로 이동'),
              subtitle: Text(note.folderName ?? AppText.messageNoFolder),
              onTap: () {
                Navigator.pop(context);
                onMoveToFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.teal),
              title: const Text('복사본 생성'),
              subtitle: const Text('이 노트의 사본 만들기'),
              onTap: () {
                Navigator.pop(context);
                onDuplicate();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('공유'),
              subtitle: const Text('다른 사람과 공유하기'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.indigo),
              title: const Text('내보내기'),
              subtitle: const Text('PDF, 텍스트 등으로 내보내기'),
              onTap: () {
                Navigator.pop(context);
                onExport();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('휴지통으로 이동'),
              subtitle: const Text(AppText.dialogDeletePermanent),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
