// note_widgets.dart 파일 내용 .ㅇd

import 'package:flutter/material.dart';

// 외부 파일에서 모델을 가져옵니다.
import 'models.dart';

// ====================================================
// 3. 그리기 에디터 위젯
// ====================================================

/// 노트를 편집하고 그림을 그릴 수 있는 에디터 위젯
class DrawingEditor extends StatefulWidget {
  final Note note; // 편집할 노트
  final VoidCallback onBack; // 뒤로가기 버튼 콜백
  final VoidCallback onSave; // 저장 콜백

  const DrawingEditor({
    super.key,
    required this.note,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

/// 그리기 에디터의 상태를 관리하는 클래스
class _DrawingEditorState extends State<DrawingEditor> {
  // ==================== 그리기 상태 변수들 ====================
  List<DrawingStroke> strokes = [];
  List<Offset> currentStroke = [];
  List<DrawingStroke> undoneStrokes = [];
  DrawingTool selectedTool = DrawingTool.pen;
  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;

  final List<Color> colorPalette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    strokes = List.from(widget.note.strokes);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentStroke = [details.localPosition];
      undoneStrokes.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentStroke.isNotEmpty) {
      setState(() {
        strokes.add(
          DrawingStroke(
            points: List.from(currentStroke),
            color: selectedColor,
            width: strokeWidth,
            tool: selectedTool,
          ),
        );
        currentStroke = [];
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      });
    }
  }

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoneStrokes.add(strokes.removeLast());
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      });
    }
  }

  void _redo() {
    if (undoneStrokes.isNotEmpty) {
      setState(() {
        strokes.add(undoneStrokes.removeLast());
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEditorAppBar(),
        _buildDrawingToolbar(),
        Expanded(child: _buildCanvas()),
      ],
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: DrawingPainter(
            strokes: strokes,
            currentStroke: currentStroke,
            currentColor: selectedColor,
            currentWidth: strokeWidth,
            currentTool: selectedTool,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildEditorAppBar() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: widget.note.title),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '제목',
              ),
              onChanged: (value) {
                widget.note.title = value;
                widget.onSave();
              },
            ),
          ),
          IconButton(
            icon: Icon(
              widget.note.isStarred ? Icons.star : Icons.star_border,
              color: widget.note.isStarred ? Colors.amber : Colors.black,
            ),
            onPressed: () {
              setState(() {
                widget.note.isStarred = !widget.note.isStarred;
              });
              widget.onSave();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildToolButton(Icons.brush, DrawingTool.pen),
          _buildToolButton(Icons.edit, DrawingTool.pencil),
          _buildToolButton(Icons.format_color_text, DrawingTool.highlighter),
          _buildToolButton(Icons.cleaning_services, DrawingTool.eraser),
          const VerticalDivider(),
          ...colorPalette.map((color) => _buildColorButton(color)),
          const Spacer(),
          SizedBox(
            width: 150,
            child: Slider(
              value: strokeWidth,
              min: 1,
              max: 10,
              onChanged: (value) {
                setState(() {
                  strokeWidth = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: undoneStrokes.isNotEmpty ? _redo : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingTool tool) {
    final isSelected = selectedTool == tool;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      )
          : null,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: () {
          setState(() {
            selectedTool = tool;
          });
        },
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = selectedColor == color;
    return InkWell(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

// ====================================================
// 4. 노트 카드 위젯
// ====================================================

/// 노트 목록에서 하나의 노트를 표시하는 카드 위젯
class NoteCard extends StatelessWidget {
  final Note note;
  final bool isHovered;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool> onHover;
  final VoidCallback onToggleStar;
  final VoidCallback onQuickPreview;
  final VoidCallback onMoreOptions;

  const NoteCard({
    super.key,
    required this.note,
    required this.isHovered,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onLongPress,
    required this.onHover,
    required this.onToggleStar,
    required this.onQuickPreview,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: isHovered ? 8 : 4,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildCardContent(context),
              _buildStarButton(context),
              if (isSelectionMode) _buildSelectionIndicator(context),
              if (isHovered && !isSelectionMode) _buildQuickPreviewButton(),
              if (!isSelectionMode) _buildMoreOptionsButton(context),
              if (note.isLocked) _buildLockedOverlay(),
              if (note.isHidden) _buildHiddenOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: DrawingPainter(
                strokes: note.strokes,
                currentStroke: const [],
                currentColor: Colors.transparent,
                currentWidth: 0,
                currentTool: DrawingTool.pen,
              ),
              child: Center(child: Text(note.content)),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title.isNotEmpty)
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: onToggleStar,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            note.isStarred ? Icons.star : Icons.star_border,
            color: note.isStarred ? Colors.amber : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? Colors.blue : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildQuickPreviewButton() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.visibility, size: 20),
        onPressed: onQuickPreview,
      ),
    );
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: GestureDetector(
        onTap: onMoreOptions,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.more_vert, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return const Positioned.fill(
      child: Center(child: Icon(Icons.lock, size: 40, color: Colors.white54)),
    );
  }

  Widget _buildHiddenOverlay() {
    return const Positioned.fill(
      child: Center(
        child: Icon(Icons.visibility_off, size: 40, color: Colors.white54),
      ),
    );
  }
}

// ====================================================
// 5. 커스텀 페인터 (그리기용)
// ====================================================

/// 캔버스에 그림을 그리는 커스텀 페인터 클래스
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final DrawingTool currentTool;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final isHighlighter = stroke.tool == DrawingTool.highlighter;
      final paint = Paint()
        ..color = isHighlighter
            ? stroke.color.withValues(alpha: 0.3)
            : stroke.color
        ..strokeWidth = isHighlighter
            ? stroke.width * 2
            : stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (currentStroke.isNotEmpty) {
      final isHighlighter = currentTool == DrawingTool.highlighter;
      final paint = Paint()
        ..color = isHighlighter
            ? currentColor.withValues(alpha: 0.3)
            : currentColor
        ..strokeWidth = isHighlighter ? currentWidth * 2 : currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}