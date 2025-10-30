// header.dart
// 노트 홈 페이지의 상단 헤더 바
// 제목, 정렬 옵션, 뷰 모드 전환 등을 제공합니다

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

/// 노트 헤더 바 (일반 모드)
/// 현재 보고 있는 노트 목록의 제목과 필터 옵션을 표시합니다
class NotesHeaderBar extends StatelessWidget {
  final int selectedMenuIndex;
  final String? selectedFolderName;
  final ViewMode viewMode;
  final SortMode sortMode;
  final int filteredNotesCount;
  final ValueChanged<SortMode> onSortChanged;
  final VoidCallback onViewModeChanged;
  final VoidCallback onMoreOptions;

  const NotesHeaderBar({
    super.key,
    required this.selectedMenuIndex,
    required this.selectedFolderName,
    required this.viewMode,
    required this.sortMode,
    required this.filteredNotesCount,
    required this.onSortChanged,
    required this.onViewModeChanged,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXLarge,
        vertical: AppSizes.paddingMedium,
      ),
      child: Row(
        children: [
          // 제목
          Text(
            _getHeaderTitle(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXLarge,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          // 노트 개수
          Text(
            filteredNotesCount.toString(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: AppSizes.fontLarge,
            ),
          ),
          const SizedBox(width: 20),
          // 정렬 옵션
          PopupMenuButton<SortMode>(
            icon: Row(
              children: [
                const Icon(
                  Icons.sort,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconLarge,
                ),
                const SizedBox(width: 4),
                Text(
                  _getSortModeText(sortMode),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontMedium,
                  ),
                ),
              ],
            ),
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortMode.modifiedDate,
                child: Text('최근 수정일'),
              ),
              const PopupMenuItem(
                value: SortMode.createdDate,
                child: Text('생성일'),
              ),
              const PopupMenuItem(
                value: SortMode.name,
                child: Text('이름'),
              ),
              const PopupMenuItem(
                value: SortMode.starred,
                child: Text('즐겨찾기 우선'),
              ),
            ],
          ),
          const Spacer(),
          // 뷰 모드 및 더보기 버튼
          Row(
            children: [
              IconButton(
                icon: Icon(
                  viewMode == ViewMode.grid
                      ? Icons.grid_view
                      : viewMode == ViewMode.list
                      ? Icons.view_list
                      : Icons.timeline,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconLarge,
                ),
                onPressed: onViewModeChanged,
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconLarge,
                ),
                onPressed: onMoreOptions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 헤더 제목 반환
  String _getHeaderTitle() {
    if (selectedFolderName != null) {
      return selectedFolderName!;
    }

    switch (selectedMenuIndex) {
      case 1:
        return '즐겨찾기';
      case 2:
        return '최근 노트';
      case 3:
        return '휴지통';
      case 4:
        return '잠긴 노트';
      case 5:
        return '숨겨진 노트';
      default:
        return '모든 노트';
    }
  }

  /// 정렬 모드 텍스트 반환
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
}

/// 노트 헤더 바 (선택 모드)
/// 여러 노트를 선택했을 때 표시되는 헤더입니다
class NotesSelectionHeaderBar extends StatelessWidget {
  final int selectedCount;
  final bool isTrashMode;
  final VoidCallback onClose;
  final VoidCallback? onMoveFolder;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;

  const NotesSelectionHeaderBar({
    super.key,
    required this.selectedCount,
    required this.isTrashMode,
    required this.onClose,
    this.onMoveFolder,
    this.onDelete,
    this.onRestore,
    this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXLarge,
        vertical: AppSizes.paddingMedium,
      ),
      child: isTrashMode
          ? _buildTrashSelectionHeader()
          : _buildNormalSelectionHeader(),
    );
  }

  /// 일반 모드 선택 헤더
  Widget _buildNormalSelectionHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: onClose,
        ),
        Text(
          '$selectedCount${AppText.messageSelected}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontXLarge,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.folder, color: AppColors.textPrimary),
          onPressed: onMoveFolder,
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.textPrimary,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }

  /// 휴지통 모드 선택 헤더
  Widget _buildTrashSelectionHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: onClose,
        ),
        Text(
          '$selectedCount${AppText.messageSelected}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontXLarge,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onRestore,
          child: const Text(
            AppText.buttonRestore,
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: onPermanentDelete,
        ),
      ],
    );
  }
}

/// 노트 헤더 바 (휴지통 모드)
/// 휴지통 화면의 헤더입니다
class TrashHeaderBar extends StatelessWidget {
  final int trashNotesCount;
  final VoidCallback onEmptyTrash;

  const TrashHeaderBar({
    super.key,
    required this.trashNotesCount,
    required this.onEmptyTrash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXLarge,
        vertical: AppSizes.paddingMedium,
      ),
      child: Row(
        children: [
          const Text(
            AppText.sidebarTrash,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXLarge,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Text(
            trashNotesCount.toString(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: AppSizes.fontLarge,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onEmptyTrash,
            child: const Text(
              '모두 비우기',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
