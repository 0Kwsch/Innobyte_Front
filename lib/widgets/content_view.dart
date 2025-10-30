// content_view.dart
// 노트 콘텐츠 뷰 (그리드, 리스트, 타임라인)
// 노트 목록을 다양한 형식으로 표시합니다

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import 'note_card.dart';

/// 노트 콘텐츠 뷰
/// 그리드, 리스트, 타임라인 뷰를 제공합니다
class NotesContentView extends StatelessWidget {
  final List<Note> filteredNotes;
  final ViewMode viewMode;
  final bool isSelectionMode;
  final Set<Note> selectedNotes;
  final ValueChanged<Note> onNoteTap;
  final Function(Note) onToggleStar;
  final Function(Note) onQuickPreview;
  final Function(Note) onMoreOptions;
  final Function(Note, bool)? onHover;

  const NotesContentView({
    super.key,
    required this.filteredNotes,
    required this.viewMode,
    required this.isSelectionMode,
    required this.selectedNotes,
    required this.onNoteTap,
    required this.onToggleStar,
    required this.onQuickPreview,
    required this.onMoreOptions,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    // 노트가 없을 때
    if (filteredNotes.isEmpty) {
      return _buildEmptyState();
    }

    // 뷰 모드에 따라 다른 레이아웃
    switch (viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.timeline:
        return _buildTimelineView();
    }
  }

  /// 빈 상태 UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Text(
            AppText.messageEmptyNotes,
            style: TextStyle(
              fontSize: AppSizes.fontLarge,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            AppText.messageEmptyNotesHint,
            style: TextStyle(
              fontSize: AppSizes.fontMedium,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 그리드 뷰
  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXLarge),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / AppSizes.gridViewMinWidth)
              .floor()
              .clamp(AppSizes.gridViewMinCrossAxisCount,
              AppSizes.gridViewMaxCrossAxisCount);

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.gridViewCrossAxisSpacing,
              mainAxisSpacing: AppSizes.gridViewMainAxisSpacing,
              childAspectRatio: AppSizes.gridViewItemAspectRatio,
            ),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return NoteCardWidget(
                note: note,
                isSelected: selectedNotes.contains(note),
                isSelectionMode: isSelectionMode,
                onTap: () => onNoteTap(note),
                onToggleStar: () => onToggleStar(note),
                onQuickPreview: () => onQuickPreview(note),
                onMoreOptions: () => onMoreOptions(note),
                onHover: (isHovering) => onHover?.call(note, isHovering),
              );
            },
          );
        },
      ),
    );
  }

  /// 리스트 뷰
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingXLarge),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return Card(
          margin: const EdgeInsets.only(
            bottom: AppSizes.paddingMedium,
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                BorderRadius.circular(AppSizes.radiusMedium),
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
                  style: TextStyle(
                    fontSize: AppSizes.fontSmall,
                    color: Colors.grey[600],
                  ),
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
                  onPressed: () => onToggleStar(note),
                ),
                if (note.tags.isNotEmpty)
                  const Icon(Icons.label, color: Colors.blue, size: 20),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => onMoreOptions(note),
                ),
              ],
            ),
            onTap: () => onNoteTap(note),
          ),
        );
      },
    );
  }

  /// 타임라인 뷰
  Widget _buildTimelineView() {
    final groupedNotes = <String, List<Note>>{};
    for (var note in filteredNotes) {
      final dateKey =
          '${note.date.year}-${note.date.month.toString().padLeft(2, '0')}-${note.date.day.toString().padLeft(2, '0')}';
      groupedNotes.putIfAbsent(dateKey, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingXLarge),
      itemCount: groupedNotes.length,
      itemBuilder: (context, index) {
        final dateKey = groupedNotes.keys.elementAt(index);
        final notesForDate = groupedNotes[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingLarge,
              ),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: AppSizes.fontXLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...notesForDate.map(
                  (note) => Card(
                margin: const EdgeInsets.only(
                  bottom: AppSizes.paddingSmall,
                ),
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onNoteTap(note),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
