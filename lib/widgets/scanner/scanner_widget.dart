import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerWidget extends StatefulWidget {
  final Function(String) onScanComplete;
  final String? overlayText;

  const ScannerWidget({
    Key? key,
    required this.onScanComplete,
    this.overlayText,
  }) : super(key: key);

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  MobileScannerController controller = MobileScannerController(
    // Updated configuration for mobile_scanner ^4.0.1
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (BarcodeCapture capture) { // Updated callback signature
            if (isScanning && capture.barcodes.isNotEmpty) {
              final String code = capture.barcodes.first.rawValue ?? '';
              if (code.isNotEmpty) {
                setState(() {
                  isScanning = false;
                });
                widget.onScanComplete(code);
              }
            }
          },
        ),
        
        // Overlay
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),
        ),
        
        // Top overlay text
        if (widget.overlayText != null)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Text(
                widget.overlayText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // Control buttons
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Torch button
              IconButton(
                onPressed: () => controller.toggleTorch(),
                icon: ValueListenableBuilder(
                  valueListenable: controller.torchState,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                      color: Colors.white,
                      size: 32,
                    );
                  },
                ),
              ),
              
              // Camera switch button
              IconButton(
                onPressed: () => controller.switchCamera(),
                icon: ValueListenableBuilder(
                  valueListenable: controller.cameraFacingState,
                  builder: (context, state, child) {
                    return Icon(
                      state == CameraFacing.front 
                          ? Icons.camera_front 
                          : Icons.camera_rear,
                      color: Colors.white,
                      size: 32,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Keep your existing QrScannerOverlayShape class - it doesn't need changes
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mSize = cutOutSize;
    final centerWidth = width / 2 + borderOffset - (mSize / 2);
    final centerHeight = height / 2 + borderOffset - (mSize / 2);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      centerWidth,
      centerHeight,
      mSize,
      mSize,
    );

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, width, height),
      Paint(),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = overlayColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      boxPaint,
    );
    canvas.restore();

    // Draw corner borders
    final path = Path();
    
    // Top left corner
    path.moveTo(centerWidth - borderOffset, centerHeight + borderLength);
    path.lineTo(centerWidth - borderOffset, centerHeight + borderRadius);
    path.quadraticBezierTo(centerWidth - borderOffset, centerHeight - borderOffset,
        centerWidth + borderRadius, centerHeight - borderOffset);
    path.lineTo(centerWidth + borderLength, centerHeight - borderOffset);

    // Top right corner
    path.moveTo(centerWidth + mSize - borderLength, centerHeight - borderOffset);
    path.lineTo(centerWidth + mSize - borderRadius, centerHeight - borderOffset);
    path.quadraticBezierTo(centerWidth + mSize + borderOffset, centerHeight - borderOffset,
        centerWidth + mSize + borderOffset, centerHeight + borderRadius);
    path.lineTo(centerWidth + mSize + borderOffset, centerHeight + borderLength);

    // Bottom right corner
    path.moveTo(centerWidth + mSize + borderOffset, centerHeight + mSize - borderLength);
    path.lineTo(centerWidth + mSize + borderOffset, centerHeight + mSize - borderRadius);
    path.quadraticBezierTo(centerWidth + mSize + borderOffset, centerHeight + mSize + borderOffset,
        centerWidth + mSize - borderRadius, centerHeight + mSize + borderOffset);
    path.lineTo(centerWidth + mSize - borderLength, centerHeight + mSize + borderOffset);

    // Bottom left corner
    path.moveTo(centerWidth + borderLength, centerHeight + mSize + borderOffset);
    path.lineTo(centerWidth + borderRadius, centerHeight + mSize + borderOffset);
    path.quadraticBezierTo(centerWidth - borderOffset, centerHeight + mSize + borderOffset,
        centerWidth - borderOffset, centerHeight + mSize - borderRadius);
    path.lineTo(centerWidth - borderOffset, centerHeight + mSize - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
