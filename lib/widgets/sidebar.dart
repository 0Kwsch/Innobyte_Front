// sidebar.dart
// 노트 홈 페이지의 왼쪽 사이드바 위젯
// 메뉴 항목, 폴더, 검색 바 등을 포함합니다

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

/// 노트 사이드바 위젯
/// 메뉴 선택, 폴더 관리, 검색 기능을 제공합니다
class NotesSidebarWidget extends StatelessWidget {
  final int selectedMenuIndex;
  final String? selectedFolderName;
  final List<Folder> folders;
  final List<Note> notes;
  final bool isSidebarCollapsed;
  final bool isAutoSaving;
  final ValueChanged<int> onMenuTapped;
  final ValueChanged<String?> onFolderSelected;
  final VoidCallback onToggleCollapse;
  final VoidCallback onCreateNewNote;
  final VoidCallback onCreateFolder;
  final VoidCallback onSettings;
  final Function(Folder) onFolderOptions;

  const NotesSidebarWidget({
    super.key,
    required this.selectedMenuIndex,
    required this.selectedFolderName,
    required this.folders,
    required this.notes,
    required this.isSidebarCollapsed,
    required this.isAutoSaving,
    required this.onMenuTapped,
    required this.onFolderSelected,
    required this.onToggleCollapse,
    required this.onCreateNewNote,
    required this.onCreateFolder,
    required this.onSettings,
    required this.onFolderOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (isSidebarCollapsed) {
      return _buildCollapsedSidebar();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSidebarHeader(),
            _buildSearchBar(),
            const SizedBox(height: AppSizes.paddingMedium),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSidebarItem(
                      Icons.all_inbox,
                      AppText.sidebarAllNotes,
                      _getActiveNotesCount(),
                      0,
                    ),
                    _buildSidebarItem(
                      Icons.star_border,
                      AppText.sidebarStarred,
                      _getStarredCount(),
                      1,
                    ),
                    _buildSidebarItem(
                      Icons.access_time,
                      AppText.sidebarRecent,
                      _getRecentCount(),
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
                      AppText.sidebarLocked,
                      _getLockedCount(),
                      4,
                    ),
                    _buildSidebarItem(
                      Icons.visibility_off_outlined,
                      AppText.sidebarHidden,
                      _getHiddenCount(),
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
                      AppText.sidebarTrash,
                      _getTrashCount(),
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

  /// 접힌 사이드바
  Widget _buildCollapsedSidebar() {
    return Container(
      color: AppColors.sidebarDark,
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: onToggleCollapse,
          ),
        ],
      ),
    );
  }

  /// 사이드바 헤더 (로고 및 옵션)
  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: const Icon(
              Icons.note_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          const Expanded(
            child: Text(
              'Samsung Notes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontXLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onSelected: (value) {
              switch (value) {
                case 'new_note':
                  onCreateNewNote();
                  break;
                case 'new_folder':
                  onCreateFolder();
                  break;
                case 'collapse':
                  onToggleCollapse();
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

  /// 검색 바
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.sidebarHeaderDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontMedium,
          ),
          decoration: InputDecoration(
            hintText: '노트 검색...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: AppSizes.fontMedium,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
              size: AppSizes.iconMedium,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  /// 사이드바 메뉴 항목
  Widget _buildSidebarItem(
    IconData icon,
    String label,
    int count,
    int index,
  ) {
    final isSelected = selectedMenuIndex == index;
    return InkWell(
      onTap: () => onMenuTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSmall,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarHoverDark : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: AppSizes.iconLarge),
            const SizedBox(width: AppSizes.paddingMedium),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontMedium,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 폴더 섹션
  Widget _buildFolderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
            vertical: AppSizes.paddingSmall,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.folder,
                color: AppColors.textSecondary,
                size: AppSizes.iconMedium,
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              const Text(
                AppText.sidebarFolders,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onCreateFolder,
                child: const Icon(
                  Icons.add,
                  color: AppColors.textSecondary,
                  size: AppSizes.iconMedium,
                ),
              ),
            ],
          ),
        ),
        ...folders.map((folder) => _buildFolderTile(folder)),
      ],
    );
  }

  /// 폴더 타일
  Widget _buildFolderTile(Folder folder) {
    final isSelected = selectedFolderName == folder.name;
    final folderNoteCount = notes
        .where((n) => n.folderName == folder.name && !n.isInTrash)
        .length;

    return InkWell(
      onTap: () => onFolderSelected(folder.name),
      onLongPress: () => onFolderOptions(folder),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSmall,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarHoverDark : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: folder.color,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontSmall,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (folderNoteCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? folder.color : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  folderNoteCount.toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 사이드바 푸터 (설정 버튼 및 저장 상태)
  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.sidebarHeaderDark,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSettings,
                  icon: const Icon(
                    Icons.settings,
                    color: AppColors.textPrimary,
                    size: AppSizes.iconMedium,
                  ),
                  label: const Text(
                    '설정',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontMedium,
                    ),
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
            const SizedBox(height: AppSizes.paddingSmall),
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
                const SizedBox(width: AppSizes.paddingSmall),
                Text(
                  AppText.messageSaving,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: AppSizes.fontSmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 헬퍼 메서드 ====================
  int _getActiveNotesCount() {
    return notes.where((n) => !n.isInTrash).length;
  }

  int _getStarredCount() {
    return notes.where((n) => n.isStarred && !n.isInTrash).length;
  }

  int _getRecentCount() {
    return notes
        .where((n) =>
    !n.isInTrash &&
        n.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    )
        .length;
  }

  int _getLockedCount() {
    return notes.where((n) => n.isLocked && !n.isInTrash).length;
  }

  int _getHiddenCount() {
    return notes.where((n) => n.isHidden && !n.isInTrash).length;
  }

  int _getTrashCount() {
    return notes.where((n) => n.isInTrash).length;
  }
}
