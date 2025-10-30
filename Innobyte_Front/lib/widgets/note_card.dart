// note_card.dart
// 개별 노트 카드 위젯
// 노트 정보를 카드 형식으로 표시합니다

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

/// 노트 카드 위젯
/// 그리드 뷰에서 개별 노트를 표시합니다
class NoteCardWidget extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onToggleStar;
  final VoidCallback onQuickPreview;
  final VoidCallback onMoreOptions;
  final Function(bool)? onHover;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onToggleStar,
    required this.onQuickPreview,
    required this.onMoreOptions,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: isSelected ? 8 : 2,
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.2)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            side: isSelected
                ? BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            )
                : BorderSide.none,
          ),
          child: Stack(
            children: [
              // 메인 콘텐츠
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppSizes.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    // 내용 미리보기
                    Text(
                      note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontMedium,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    // 날짜 및 태그
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${note.date.year}-${note.date.month}-${note.date.day}',
                          style: TextStyle(
                            fontSize: AppSizes.fontSmall,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (note.tags.isNotEmpty)
                          Flexible(
                            child: Wrap(
                              spacing: 4,
                              children: note.tags
                                  .take(2)
                                  .map(
                                    (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSmall,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // 선택 모드 체크박스
              if (isSelectionMode)
                Positioned(
                  top: AppSizes.paddingMedium,
                  right: AppSizes.paddingMedium,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.white,
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                        : null,
                  ),
                ),
              // 일반 모드 액션 버튼
              if (!isSelectionMode)
                Positioned(
                  top: AppSizes.paddingMedium,
                  right: AppSizes.paddingMedium,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 즐겨찾기 버튼
                      IconButton(
                        icon: Icon(
                          note.isStarred ? Icons.star : Icons.star_border,
                          color: note.isStarred ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onToggleStar,
                        splashRadius: 16,
                      ),
                      // 더보기 버튼
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'preview':
                              onQuickPreview();
                              break;
                            case 'more':
                              onMoreOptions();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'preview',
                            child: Text('빠른 보기'),
                          ),
                          const PopupMenuItem(
                            value: 'more',
                            child: Text('더보기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // 상태 배지
              if (note.isLocked || note.isHidden)
                Positioned(
                  bottom: AppSizes.paddingMedium,
                  right: AppSizes.paddingMedium,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isLocked)
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.orange,
                        ),
                      if (note.isHidden)
                        const SizedBox(width: 4),
                      if (note.isHidden)
                        Icon(
                          Icons.visibility_off,
                          size: 16,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
