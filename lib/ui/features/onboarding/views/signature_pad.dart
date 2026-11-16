import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 손가락으로 그리는 서명 칸. 손을 뗄 때마다 PNG 바이트를 [onChanged] 로 넘긴다.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, required this.onChanged});

  final ValueChanged<Uint8List?> onChanged;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;
  int? _pointer;

  @override
  void initState() {
    super.initState();
    // 단계를 오가면 칸은 비어 있는데 이전 서명 값이 남아 검사를 통과하던 문제를 막는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(null));
  }

  // 손가락은 칸 밖으로 나가도 계속 따라온다. 칸 밖에서는 선을 끊고, 다시 들어오면 새 선으로 시작한다.
  bool _inside(Offset o) => o.dx >= 0 && o.dy >= 0 && o.dx <= _size.width && o.dy <= _size.height;
  bool _out = false;

  void clear() {
    setState(_strokes.clear);
    widget.onChanged(null);
  }

  Future<void> _export() async {
    final recorder = ui.PictureRecorder();
    _SignaturePainter(_strokes).paint(Canvas(recorder), _size);
    final img = await recorder.endRecording().toImage(_size.width.ceil(), _size.height.ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    widget.onChanged(bytes?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _size = Size(c.maxWidth, 120);
        // 스크롤 화면 안에 있어도 서명 칸을 누르면 터치를 바로 가져와 화면이 움직이지 않게 한다.
        return RawGestureDetector(
          gestures: {EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(EagerGestureRecognizer.new, (_) {})},
          child: Listener(
            // 두 번째 손가락은 무시한다(첫 획에 이어 붙어 선이 튀는 문제).
            onPointerDown: (d) {
              if (_pointer != null) return;
              _pointer = d.pointer;
              _out = false;
              setState(() => _strokes.add([d.localPosition]));
            },
            onPointerMove: (d) {
              if (d.pointer != _pointer) return;
              final o = d.localPosition;
              if (!_inside(o)) {
                _out = true;
                return;
              }
              setState(() {
                if (_out) _strokes.add([]);
                _out = false;
                _strokes.last.add(o);
              });
            },
            onPointerUp: (d) {
              if (d.pointer != _pointer) return;
              _pointer = null;
              _export();
            },
            onPointerCancel: (d) {
              if (d.pointer == _pointer) _pointer = null;
            },
            // 그림이 칸 밖으로 번지지 않게 칸 모양으로 자른다.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                color: AppColors.fill,
                child: CustomPaint(painter: _SignaturePainter(_strokes), size: _size),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) canvas.drawCircle(s.first, 1.3, p..style = PaintingStyle.fill);
      final path = Path()..addPolygon(s, false);
      canvas.drawPath(path, p..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
