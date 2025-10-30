// note_widgets.dart 파일 내용 .ㅇd

import 'package:flutter/material.dart';
import 'dart:async' show Timer;

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

  // ==================== 올가미 선택 관련 변수 ====================
  List<Offset> lassoPath = [];
  Set<DrawingStroke> selectedStrokes = {};
  DrawingStroke? draggingStroke;
  Offset? lastDragOffset;

  // ==================== 직선 자동 보정 관련 변수 ====================
  Timer? _straightLineTimer;
  bool _isStraightening = false; // 현재 직선 보정 중인지 여부

  // ==================== 지우개 토글 관련 변수 ====================
  DrawingTool? _previousTool; // 지우개 토글 전 이전 도구

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

  @override
  void dispose() {
    _straightLineTimer?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      if (selectedTool == DrawingTool.lasso) {
        // 올가미 도구: 경로 시작
        lassoPath = [details.localPosition];
      } else if (selectedStrokes.isNotEmpty) {
        // 선택된 스트로크가 있으면 드래그로 이동
        lastDragOffset = details.localPosition;
      } else {
        // 일반 그리기
        currentStroke = [details.localPosition];
      }
      undoneStrokes.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (selectedTool == DrawingTool.lasso) {
        // 올가미 경로 추가
        lassoPath.add(details.localPosition);
        // 올가미는 타이머 취소
        _straightLineTimer?.cancel();
        _isStraightening = false;
      } else if (selectedStrokes.isNotEmpty && lastDragOffset != null) {
        // 선택된 스트로크 이동
        final delta = details.localPosition - lastDragOffset!;
        for (var stroke in selectedStrokes) {
          for (int i = 0; i < stroke.points.length; i++) {
            stroke.points[i] = stroke.points[i] + delta;
          }
        }
        lastDragOffset = details.localPosition;
      } else {
        // 일반 그리기
        currentStroke.add(details.localPosition);

        // 형광펜인 경우 타이머 시작 (첫 점 추가할 때만)
        if (selectedTool == DrawingTool.highlighter &&
            currentStroke.length == 2 &&
            !_isStraightening) {
          _startHighlighterStraightLineTimer();
        }
      }
    });
  }

  /// 형광펜 직선 자동 보정 타이머 시작
  void _startHighlighterStraightLineTimer() {
    _straightLineTimer?.cancel();
    _isStraightening = false;

    _straightLineTimer = Timer(const Duration(milliseconds: 1000), () {
      // 1초 후 현재 스트로크가 직선인지 판단
      if (currentStroke.length >= 5 && _isStraightLine(currentStroke)) {
        setState(() {
          // 직선으로 보정
          _isStraightening = true;
          currentStroke = _generateStraightLine(
            currentStroke.first,
            currentStroke.last,
            currentStroke.length,
          );
        });
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // 타이머 취소
    _straightLineTimer?.cancel();

    setState(() {
      if (selectedTool == DrawingTool.lasso && lassoPath.isNotEmpty) {
        // 올가미로 선택된 스트로크 찾기
        _selectStrokesWithinLasso();
        lassoPath = [];
      } else if (selectedStrokes.isEmpty && currentStroke.isNotEmpty) {
        // 일반 그리기 완료
        final newStroke = DrawingStroke(
          points: List.from(currentStroke),
          color: selectedColor,
          width: strokeWidth,
          tool: selectedTool,
        );

        strokes.add(newStroke);
        currentStroke = [];
        widget.note.strokes = List.from(strokes);
        widget.onSave();

        _isStraightening = false;
      } else if (selectedStrokes.isNotEmpty) {
        // 드래그 이동 완료
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      }
      lastDragOffset = null;
    });
  }

  /// 스트로크가 대략 직선인지 판단
  bool _isStraightLine(List<Offset> points) {
    if (points.length < 5) return false;

    // 시작점과 끝점을 잇는 직선과 각 점의 거리를 계산
    final startPoint = points.first;
    final endPoint = points.last;

    // 전체 거리
    final totalDistance = (endPoint - startPoint).distance;
    if (totalDistance < 10) return false; // 너무 짧으면 무시

    // 각 점과 직선의 거리 계산
    double maxDeviation = 0;
    double totalDeviation = 0;
    int deviationCount = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _pointToLineDistance(
        points[i],
        startPoint,
        endPoint,
      );
      maxDeviation = distance > maxDeviation ? distance : maxDeviation;
      totalDeviation += distance;
      deviationCount++;
    }

    // 평균 편차가 작으면 직선으로 판정
    final avgDeviation = totalDeviation / deviationCount;
    return avgDeviation < 15 && maxDeviation < 30; // 임계값 조정 가능
  }

  /// 점에서 선분까지의 거리 계산
  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final denominator = dx * dx + dy * dy;

    if (denominator == 0) {
      // 시작점과 끝점이 같은 경우
      return (point - lineStart).distance;
    }

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        denominator;
    final tClamped = t < 0 ? 0 : (t > 1 ? 1 : t);
    final closestPoint = Offset(
      lineStart.dx + tClamped * dx,
      lineStart.dy + tClamped * dy,
    );

    return (point - closestPoint).distance;
  }

  /// 시작점과 끝점을 잇는 일직선 생성
  List<Offset> _generateStraightLine(
    Offset start,
    Offset end,
    int pointCount,
  ) {
    final straightPoints = <Offset>[];
    for (int i = 0; i < pointCount; i++) {
      final t = i / (pointCount - 1);
      straightPoints.add(
        Offset(
          start.dx + (end.dx - start.dx) * t,
          start.dy + (end.dy - start.dy) * t,
        ),
      );
    }
    return straightPoints;
  }

  /// 올가미 경로 내에 있는 스트로크 선택
  void _selectStrokesWithinLasso() {
    selectedStrokes.clear();
    for (var stroke in strokes) {
      if (_isStrokeWithinLasso(stroke)) {
        selectedStrokes.add(stroke);
      }
    }
  }

  /// 스트로크가 올가미 경로 내에 있는지 확인
  bool _isStrokeWithinLasso(DrawingStroke stroke) {
    for (var point in stroke.points) {
      if (_isPointWithinLasso(point)) {
        return true;
      }
    }
    return false;
  }

  /// 점이 올가미 경로 내에 있는지 확인 (간단한 다각형 내부 판별)
  bool _isPointWithinLasso(Offset point) {
    if (lassoPath.length < 3) return false;

    int intersections = 0;
    for (int i = 0; i < lassoPath.length; i++) {
      final p1 = lassoPath[i];
      final p2 = lassoPath[(i + 1) % lassoPath.length];

      if (_lineIntersectsRay(p1, p2, point)) {
        intersections++;
      }
    }
    return intersections % 2 == 1;
  }

  /// 선분이 점에서 시작하는 광선과 교차하는지 확인
  bool _lineIntersectsRay(Offset p1, Offset p2, Offset point) {
    if ((p1.dy <= point.dy && point.dy < p2.dy) ||
        (p2.dy <= point.dy && point.dy < p1.dy)) {
      final x = (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx;
      if (point.dx < x) {
        return true;
      }
    }
    return false;
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
        if (widget.note.attachedPdfs.isNotEmpty) _buildPDFSection(),
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
            lassoPath: lassoPath,
            selectedStrokes: selectedStrokes,
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
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 그리기 도구
          _buildEnhancedToolButton(
            icon: Icons.brush,
            tool: DrawingTool.pen,
            label: '볼펜',
          ),
          _buildEnhancedToolButton(
            icon: Icons.edit,
            tool: DrawingTool.highlighter,
            label: '형광펜',
          ),
          _buildEraserToggleButton(),
          _buildEnhancedToolButton(
            icon: Icons.gesture,
            tool: DrawingTool.lasso,
            label: '자유로운 곡선',
          ),
          const VerticalDivider(indent: 10, endIndent: 10),

          // 색상 팔레트
          ...colorPalette.map((color) => _buildColorButton(color)),
          const Spacer(),

          // 선 굵기 조절
          SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Slider(
                  value: strokeWidth,
                  min: 1,
                  max: 10,
                  onChanged: selectedTool == DrawingTool.lasso
                      ? null
                      : (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                ),
                Text(
                  '${strokeWidth.toStringAsFixed(1)}px',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '실행 취소',
            onPressed: strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '다시 실행',
            onPressed: undoneStrokes.isNotEmpty ? _redo : null,
          ),

          // 삭제 버튼
          if (selectedStrokes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('삭제'),
                onPressed: () {
                  setState(() {
                    strokes.removeWhere((s) => selectedStrokes.contains(s));
                    selectedStrokes.clear();
                    widget.note.strokes = List.from(strokes);
                    widget.onSave();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 지우개 토글 버튼 - 누르면 지우개 on/off
  Widget _buildEraserToggleButton() {
    final isEraserMode = selectedTool == DrawingTool.eraser;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isEraserMode
          ? BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
      child: IconButton(
        icon: Icon(
          Icons.cleaning_services,
          color: isEraserMode ? Colors.blue : Colors.black,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            if (isEraserMode) {
              // 지우개 모드 해제 - 이전 도구로 복귀 (없으면 볼펜)
              selectedTool = _previousTool ?? DrawingTool.pen;
              _previousTool = null;
            } else {
              // 지우개 모드 활성화 - 현재 도구 저장
              _previousTool = selectedTool;
              selectedTool = DrawingTool.eraser;
            }
            selectedStrokes.clear(); // 도구 변경 시 선택 해제
          });
        },
      ),
    );
  }

  /// 향상된 도구 버튼 - 하이라이트 포함
  Widget _buildEnhancedToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String label,
  }) {
    final isSelected = selectedTool == tool;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.black,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            selectedTool = tool;
            selectedStrokes.clear(); // 도구 변경 시 선택 해제
            _previousTool = null; // 다른 도구 선택 시 이전 도구 초기화
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

  /// PDF 파일 섹션 빌드
  Widget _buildPDFSection() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'PDF 파일 (${widget.note.attachedPdfs.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.note.attachedPdfs.map((pdf) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // PDF 열기 기능 (나중에 구현)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${pdf.name} 열기 준비 중...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: Text(
                                pdf.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.note.attachedPdfs.removeWhere((p) => p.path == pdf.path);
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pdf.fileSize.toStringAsFixed(2)} MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
  final List<Offset> lassoPath;
  final Set<DrawingStroke> selectedStrokes;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
    this.lassoPath = const [],
    this.selectedStrokes = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 저장된 모든 스트로크 그리기
    for (var stroke in strokes) {
      final isHighlighter = stroke.tool == DrawingTool.highlighter;
      final isEraser = stroke.tool == DrawingTool.eraser;
      final isSelected = selectedStrokes.contains(stroke);

      if (isHighlighter) {
        // 형광펜: 예쁜 반투명 효과로 렌더링
        _drawHighlighterStroke(canvas, stroke);
      } else if (isEraser) {
        // 지우개: 흰색 선으로 표현 (투명 처리용)
        final paint = Paint()
          ..color = Colors.white
          ..strokeWidth = stroke.width * 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      } else {
        // 일반 펜: 기본 그리기
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }

      // 선택된 스트로크는 파란색 테두리로 표시
      if (isSelected) {
        final boundingBox = _getBoundingBox(stroke.points);
        final selectionPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawRect(boundingBox, selectionPaint);
      }
    }

    // 2. 현재 그리는 스트로크
    if (currentStroke.isNotEmpty) {
      final isHighlighter = currentTool == DrawingTool.highlighter;
      final isEraser = currentTool == DrawingTool.eraser;

      if (isHighlighter) {
        // 형광펜: 예쁜 반투명 효과로 렌더링
        _drawHighlighterStrokeForCurrent(canvas, currentStroke);
      } else if (isEraser) {
        // 지우개: 흰색 선으로 표현
        final paint = Paint()
          ..color = Colors.white
          ..strokeWidth = currentWidth * 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < currentStroke.length - 1; i++) {
          canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
        }
      } else {
        // 일반 펜: 기본 그리기
        final paint = Paint()
          ..color = currentColor
          ..strokeWidth = currentWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < currentStroke.length - 1; i++) {
          canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
        }
      }
    }

    // 3. 올가미 경로 그리기
    if (lassoPath.isNotEmpty) {
      final lassoPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < lassoPath.length - 1; i++) {
        canvas.drawLine(lassoPath[i], lassoPath[i + 1], lassoPaint);
      }

      // 올가미 경로 닫기
      if (lassoPath.length > 2) {
        canvas.drawLine(lassoPath.last, lassoPath.first, lassoPaint);
      }
    }
  }

  /// 형광펜 스트로크를 예쁘게 그리기 (Path 기반으로 끊김 없이)
  void _drawHighlighterStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    // 배경: 반투명한 굵은 선 (Path 기반)
    final backgroundPath = Path();
    backgroundPath.moveTo(stroke.points[0].dx, stroke.points[0].dy);

    for (int i = 1; i < stroke.points.length; i++) {
      backgroundPath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    final backgroundPaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.25)
      ..strokeWidth = stroke.width * 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 전경: 더 진한 색상의 중간 선 (Path 기반)
    final foregroundPath = Path();
    foregroundPath.moveTo(stroke.points[0].dx, stroke.points[0].dy);

    for (int i = 1; i < stroke.points.length; i++) {
      foregroundPath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    final foregroundPaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.5)
      ..strokeWidth = stroke.width * 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(foregroundPath, foregroundPaint);
  }

  /// 형광펜 현재 스트로크를 예쁘게 그리기 (Path 기반으로 끊김 없이, 그리는 중)
  void _drawHighlighterStrokeForCurrent(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;

    // 배경: 반투명한 굵은 선 (Path 기반)
    final backgroundPath = Path();
    backgroundPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      backgroundPath.lineTo(points[i].dx, points[i].dy);
    }

    final backgroundPaint = Paint()
      ..color = currentColor.withValues(alpha: 0.25)
      ..strokeWidth = currentWidth * 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 전경: 더 진한 색상의 중간 선 (Path 기반)
    final foregroundPath = Path();
    foregroundPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      foregroundPath.lineTo(points[i].dx, points[i].dy);
    }

    final foregroundPaint = Paint()
      ..color = currentColor.withValues(alpha: 0.5)
      ..strokeWidth = currentWidth * 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(foregroundPath, foregroundPaint);
  }

  /// 점들의 경계 상자 구하기
  Rect _getBoundingBox(List<Offset> points) {
    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;

    for (var point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    return Rect.fromLTRB(minX - 5, minY - 5, maxX + 5, maxY + 5);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}