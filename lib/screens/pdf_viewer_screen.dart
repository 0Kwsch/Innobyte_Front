// pdf_viewer_screen.dart
// PDF 파일을 노트처럼 편집할 수 있는 전용 화면
// 모든 페이지를 흰 배경에 스크롤로 표시하고, 그리기 도구 지원

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import '../models.dart';
import 'dart:async' show Timer;

/// PDF를 노트 편집 화면처럼 보고 편집할 수 있는 위젯
class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfFileName;
  final Note note;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isReadMode;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.pdfFileName,
    required this.note,
    required this.onBack,
    required this.onSave,
    this.isReadMode = false,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

/// PDF 뷰어 화면의 상태 관리
class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PdfDocument pdfDocument;
  List<PdfPage> pdfPages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool isReadMode = false;

  // 그리기 관련 변수
  late List<DrawingStroke> strokes;
  List<Offset> currentStroke = [];
  List<DrawingStroke> undoneStrokes = [];
  DrawingTool selectedTool = DrawingTool.pen;
  Color selectedColor = Colors.black;
  double strokeWidth = 2.0;
  Timer? _straightLineTimer;
  bool _isStraightening = false;

  // 페이지 렌더링 캐시 (메모리 누수 방지)
  final Map<int, Future<PdfPageImage?>> _pageRenderCache = {};

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
    isReadMode = widget.isReadMode;
    _initializePDF();
  }

  /// PDF 파일 초기화 및 모든 페이지 로드
  Future<void> _initializePDF() async {
    try {
      // 이미 로드되었으면 재사용
      if (pdfPages.isNotEmpty && pdfDocument.pagesCount > 0) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 이전 PDF와 다른 경우에만 정리 (경로가 다를 때)
      if (pdfPages.isNotEmpty) {
        try {
          for (var page in pdfPages) {
            try {
              page.close();
            } catch (_) {}
          }
          pdfPages.clear();
        } catch (_) {}

        try {
          pdfDocument.close();
        } catch (_) {}

        _pageRenderCache.clear();
      }

      // 파일 존재 확인
      final file = File(widget.pdfPath);

      // 파일 접근 가능성 확인
      bool fileExists = false;
      int fileSize = 0;

      try {
        fileExists = await file.exists();
        if (fileExists) {
          fileSize = await file.length();
        }
      } catch (e) {
        // 직접 접근 실패 시도
        fileExists = File(widget.pdfPath).existsSync();
        if (fileExists) {
          fileSize = File(widget.pdfPath).lengthSync();
        }
      }

      if (!fileExists) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'PDF 파일을 찾을 수 없습니다\n\n경로: ${widget.pdfPath}\n\n'
                '확인사항:\n'
                '• 파일이 삭제되지 않았는지 확인하세요\n'
                '• 파일 권한을 확인하세요\n'
                '• 다시 선택해보세요';
            _isLoading = false;
          });
        }
        return;
      }

      if (fileSize == 0) {
        if (mounted) {
          setState(() {
            _errorMessage = 'PDF 파일이 비어있습니다\n\n크기: 0 bytes';
            _isLoading = false;
          });
        }
        return;
      }

      // PDF 문서 열기 (여러 방법 시도)
      PdfDocument? document;
      String? lastError;

      // 방법 1: 원본 경로에서 직접 로드
      try {
        document = await PdfDocument.openFile(widget.pdfPath).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('타임아웃'),
        );
      } catch (e) {
        lastError = e.toString();
        // 방법 2: 파일 읽어서 메모리에 로드
        try {
          final bytes = await file.readAsBytes();
          document = await PdfDocument.openData(bytes).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('메모리 로드 타임아웃'),
          );
        } catch (e2) {
          lastError = '$lastError\n메모리 로드: $e2';
          // 방법 3: 임시 폴더에 복사 후 로드
          try {
            final tempDir = Directory.systemTemp;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempFile = File('${tempDir.path}/pdf_temp_$timestamp.pdf');

            await file.copy(tempFile.path);

            document = await PdfDocument.openFile(tempFile.path).timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('임시 파일 로드 타임아웃'),
            );

            // 나중에 삭제하도록 예약
            Future.delayed(const Duration(seconds: 5), () {
              try {
                tempFile.deleteSync();
              } catch (_) {}
            });
          } catch (e3) {
            lastError = '$lastError\n임시 파일: $e3';
            throw Exception(lastError);
          }
        }
      }

      pdfDocument = document;

      // 페이지 수 확인
      if (pdfDocument.pagesCount == 0) {
        if (mounted) {
          setState(() {
            _errorMessage = 'PDF에 페이지가 없습니다';
            _isLoading = false;
          });
        }
        return;
      }

      // 모든 페이지 로드
      pdfPages =
          await Future.wait(
            List.generate(
              pdfDocument.pagesCount,
              (i) => pdfDocument.getPage(i + 1),
            ),
            eagerError: true,
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('페이지 로드 타임아웃'),
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'PDF 로드 실패\n\n오류: $e\n\n'
              '해결 방법:\n'
              '• 올바른 PDF 파일인지 확인하세요\n'
              '• 파일이 손상되지 않았는지 확인하세요\n'
              '• 다른 PDF를 선택해보세요';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _straightLineTimer?.cancel();

    // 참고: 캐시는 유지하여 다시 돌아올 때 빠르게 표시
    // _pageRenderCache는 clear하지 않음

    // PDF 페이지 닫기는 하지 않음 (다시 사용할 수 있음)
    // pdfPages와 pdfDocument도 유지

    super.dispose();
  }

  /// 실행 취소
  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoneStrokes.add(strokes.removeLast());
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      });
    }
  }

  /// 다시 하기
  void _redo() {
    if (undoneStrokes.isNotEmpty) {
      setState(() {
        strokes.add(undoneStrokes.removeLast());
        widget.note.strokes = List.from(strokes);
        widget.onSave();
      });
    }
  }

  /// 형광펜 직선 자동 보정 타이머 시작
  void _startHighlighterStraightLineTimer() {
    _straightLineTimer?.cancel();
    _isStraightening = false;

    _straightLineTimer = Timer(const Duration(milliseconds: 1000), () {
      if (currentStroke.length >= 5 && _isStraightLine(currentStroke)) {
        setState(() {
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

  /// 스트로크가 대략 직선인지 판단
  bool _isStraightLine(List<Offset> points) {
    if (points.length < 5) return false;

    final startPoint = points.first;
    final endPoint = points.last;
    final totalDistance = (endPoint - startPoint).distance;
    if (totalDistance < 10) return false;

    double maxDeviation = 0;
    double totalDeviation = 0;
    int deviationCount = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _pointToLineDistance(points[i], startPoint, endPoint);
      maxDeviation = distance > maxDeviation ? distance : maxDeviation;
      totalDeviation += distance;
      deviationCount++;
    }

    final avgDeviation = totalDeviation / deviationCount;
    return avgDeviation < 15 && maxDeviation < 30;
  }

  /// 점에서 선분까지의 거리 계산
  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final denominator = dx * dx + dy * dy;

    if (denominator == 0) {
      return (point - lineStart).distance;
    }

    final t =
        ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        denominator;
    final tClamped = t < 0 ? 0 : (t > 1 ? 1 : t);
    final closestPoint = Offset(
      lineStart.dx + tClamped * dx,
      lineStart.dy + tClamped * dy,
    );

    return (point - closestPoint).distance;
  }

  /// 시작점과 끝점을 잇는 일직선 생성
  List<Offset> _generateStraightLine(Offset start, Offset end, int pointCount) {
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

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentStroke = [details.localPosition];
      undoneStrokes.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(details.localPosition);

      if (selectedTool == DrawingTool.highlighter &&
          currentStroke.length == 2 &&
          !_isStraightening) {
        _startHighlighterStraightLineTimer();
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _straightLineTimer?.cancel();

    setState(() {
      if (currentStroke.isNotEmpty) {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEditorAppBar(),
        if (!isReadMode) _buildDrawingToolbar(),
        Expanded(child: _buildPDFViewer()),
      ],
    );
  }

  /// 헤더
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
            child: Text(
              widget.pdfFileName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              isReadMode ? Icons.edit : Icons.visibility,
              color: Colors.black,
            ),
            tooltip: isReadMode ? '편집 모드' : '읽기 모드',
            onPressed: () {
              setState(() {
                isReadMode = !isReadMode;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 그리기 도구 모음
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
          // 펜 도구
          _buildToolButton(
            icon: Icons.brush,
            tool: DrawingTool.pen,
            label: '펜',
          ),
          // 형광펜 도구
          _buildToolButton(
            icon: Icons.edit,
            tool: DrawingTool.highlighter,
            label: '형광펜',
          ),
          // 지우개 도구
          _buildToolButton(
            icon: Icons.cleaning_services,
            tool: DrawingTool.eraser,
            label: '지우개',
          ),
          // 올가미 도구
          _buildToolButton(
            icon: Icons.gesture,
            tool: DrawingTool.lasso,
            label: '올가미',
          ),
          const VerticalDivider(indent: 10, endIndent: 10),

          // 색상 팔레트
          ...colorPalette.map((color) => _buildColorButton(color)),
          const Spacer(),

          // 실행 취소/다시하기
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.black),
            onPressed: strokes.isNotEmpty ? _undo : null,
            tooltip: '실행 취소',
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.black),
            onPressed: undoneStrokes.isNotEmpty ? _redo : null,
            tooltip: '다시 하기',
          ),
        ],
      ),
    );
  }

  /// 도구 버튼
  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String label,
  }) {
    final isSelected = selectedTool == tool;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTool = tool;
            switch (tool) {
              case DrawingTool.pen:
                strokeWidth = 2.0;
                break;
              case DrawingTool.highlighter:
                strokeWidth = 5.0;
                break;
              case DrawingTool.eraser:
                strokeWidth = 10.0;
                break;
              default:
                strokeWidth = 2.0;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// 색상 버튼
  Widget _buildColorButton(Color color) {
    final isSelected =
        selectedColor == color && selectedTool != DrawingTool.eraser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: selectedTool != DrawingTool.eraser
            ? () {
                setState(() {
                  selectedColor = color;
                });
              }
            : null,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.pdfFileName),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 24),
            Text('PDF 로딩 중...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  /// 에러 화면
  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('오류 발생'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'PDF 파일을 로드할 수 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('뒤로가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PDF 뷰어 - 모든 페이지를 스크롤로 표시
  Widget _buildPDFViewer() {
    if (_isLoading) return _buildLoadingScreen();
    if (_errorMessage != null) return _buildErrorScreen();

    return GestureDetector(
      onPanStart: !isReadMode ? _onPanStart : null,
      onPanUpdate: !isReadMode ? _onPanUpdate : null,
      onPanEnd: !isReadMode ? _onPanEnd : null,
      child: Stack(
        children: [
          // PDF 백그라운드 - 모든 페이지를 세로로 나열
          Container(
            color: Colors.grey[300],
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  for (int i = 0; i < pdfPages.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildPDFPageWidget(pdfPages[i], i + 1),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 그리기 오버레이 (읽기 모드가 아닐 때만)
          if (!isReadMode)
            Positioned.fill(
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: strokes,
                  currentStroke: currentStroke,
                  selectedTool: selectedTool,
                  selectedColor: selectedColor,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 개별 PDF 페이지 위젯
  Widget _buildPDFPageWidget(PdfPage page, int pageNumber) {
    // 렌더링 결과 캐시
    _pageRenderCache[pageNumber] ??= page.render(width: 1400, height: 1800);

    return FutureBuilder<PdfPageImage?>(
      future: _pageRenderCache[pageNumber],
      builder: (context, snapshot) {
        // 캐시된 데이터가 있으면 즉시 표시
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.memory(
                    snapshot.data!.bytes,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '페이지 $pageNumber',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 500,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 에러
        return Container(
          width: double.infinity,
          height: 500,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('페이지 $pageNumber 로드 실패', textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 그리기를 표시하는 커스텀 페인터
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 저장된 스트로크 그리기
    for (var stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 현재 그리는 스트로크
    if (currentStroke.isNotEmpty) {
      final paint = Paint();
      paint.strokeWidth = strokeWidth;
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;
      paint.style = PaintingStyle.stroke;

      if (selectedTool == DrawingTool.eraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      } else if (selectedTool == DrawingTool.highlighter) {
        paint.color = selectedColor.withValues(alpha: 0.4);
      } else {
        paint.color = selectedColor;
      }

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.transparent;
    } else if (stroke.tool == DrawingTool.highlighter) {
      paint.color = stroke.color.withValues(alpha: 0.4);
    } else {
      paint.color = stroke.color;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
