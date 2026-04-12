import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/constants.dart';
import '../../providers/session_provider.dart';
import '../../providers/recording_provider.dart';
import '../../services/video_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final int? sessionId;
  const CameraScreen({super.key, this.sessionId});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _sessionActive = true;
  bool _isCalibrating = true;
  bool _isDetectingRunUp = false;
  bool _isProcessingImage = false;
  double? _lastHipY;
  int _runUpFrames = 0;
  
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  int _ballCount = 0;
  final _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Camera permission denied");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required to proceed.')),
        );
      }
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _cameraReady = true);
      // Wait for calibration to finish before recording loop
    }
  }

  void _finishCalibration() {
    setState(() {
      _isCalibrating = false;
      _isDetectingRunUp = true;
    });
    _startRunUpDetection();
  }

  void _unlockCalibration() {
    setState(() {
      _isCalibrating = true;
      _isDetectingRunUp = false;
    });
    _cameraController?.stopImageStream().catchError((_) {});
  }

  Future<void> _startRunUpDetection() async {
    if (!_sessionActive || !mounted || _cameraController == null) return;
    ref.read(recordingProvider.notifier).setIdle();
    
    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (_isProcessingImage || !_isDetectingRunUp) return;
        _isProcessingImage = true;
        
        try {
          await _processCameraImage(image);
        } catch (e) {
          debugPrint("ML Kit error: \$e");
        } finally {
          _isProcessingImage = false;
        }
      });
    } catch (e) {
      debugPrint("Could not start image stream: \$e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    
    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return;
    
    // Find the largest pose (likely the bowler close to camera)
    // Ignore small poses (fielders/spectators in background)
    Pose? largestPose;
    double maxBoxArea = 0;
    
    for (final pose in poses) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      
      for (final landmark in pose.landmarks.values) {
        if (landmark.x < minX) minX = landmark.x;
        if (landmark.y < minY) minY = landmark.y;
        if (landmark.x > maxX) maxX = landmark.x;
        if (landmark.y > maxY) maxY = landmark.y;
      }
      final area = (maxX - minX) * (maxY - minY);
      if (area > maxBoxArea) {
        maxBoxArea = area;
        largestPose = pose;
      }
    }
    
    if (largestPose == null) return;
    
    // Track bowling arm wrist to trigger recording
    // Assuming right-arm bowler for simple MVP logic, or check both wrists
    final rightWrist = largestPose.landmarks[PoseLandmarkType.rightWrist];
    final leftWrist = largestPose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = largestPose.landmarks[PoseLandmarkType.rightShoulder];
    final leftShoulder = largestPose.landmarks[PoseLandmarkType.leftShoulder];
    
    if (rightWrist != null && rightShoulder != null && leftWrist != null && leftShoulder != null) {
      // Find the highest wrist relative to the shoulder (arm raised for delivery)
      final rightArmRaised = (rightShoulder.y - rightWrist.y);
      final leftArmRaised = (leftShoulder.y - leftWrist.y);
      
      final currentMaxWristExtension = math.max(rightArmRaised, leftArmRaised);
      
      if (_lastHipY != null) {
        // Did wrist accelerate downwards? (Delivery action taking place)
        final delta = (_lastHipY! - currentMaxWristExtension); 
        
        // If arm was high and is now moving down fast, trigger recording
        if (currentMaxWristExtension > 20.0 && delta > 15.0) { 
          _runUpFrames++;
          if (_runUpFrames > 2) {
            // Ball release detected! Trigger recording
            _triggerAutoRecording();
            return;
          }
        } else {
          _runUpFrames = 0;
        }
      }
      _lastHipY = currentMaxWristExtension;
    }
  }

  Future<void> _triggerAutoRecording() async {
    _isDetectingRunUp = false; // Stop detection
    try {
      await _cameraController!.stopImageStream();
    } catch (e) {
      debugPrint("Error stopping stream: \$e");
    }
    
    setState(() {});
    _startRecordingSequence();
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageMetadata inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  Future<void> _startRecordingSequence() async {
    await _recordOneBall();
    // After returning, go back to run-up detection if session continues
    if (_sessionActive && mounted) {
      setState(() {
        _isDetectingRunUp = true;
        _runUpFrames = 0;
        _lastHipY = null;
      });
      _startRunUpDetection();
    }
  }

  Future<void> _recordOneBall() async {
    if (!_sessionActive || !mounted) return;

    ref.read(recordingProvider.notifier).setRecording();
    await _cameraController!.startVideoRecording();

    // Setup dynamic duration: Record for up to 5 seconds max.
    // However, if we continue running MLKit during recording and observe the ball
    // reaching the batsman, we could stop early. For mobile MVP, a strict 
    // 3.5 - 4.5 second window from ball release covers almost all human deliveries.
    await Future.delayed(const Duration(milliseconds: 3800));
    
    if (!mounted || !_sessionActive) {
      await _cameraController?.stopVideoRecording();
      return;
    }

    final file = await _cameraController!.stopVideoRecording();
    setState(() => _ballCount++);
    ref.read(recordingProvider.notifier).setUploading();

    // Fire-and-forget upload
    _uploadInBackground(file.path, _ballCount);

    // Brief pause before next delivery
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) ref.read(recordingProvider.notifier).setIdle();
  }

  Future<void> _uploadInBackground(String filePath, int ballNumber) async {
    try {
      final result = await _videoService.uploadVideo(
        filePath,
        sessionId: widget.sessionId,
      );
      final filename = result['filename'] as String? ?? '';
      if (filename.isNotEmpty) {
        ref.read(sessionProvider.notifier).addDelivery(filename, ballNumber);
        // Poll for analysis in background
        _videoService.fetchTrajectory(filename).then((analysis) {
          if (analysis != null) {
            ref.read(sessionProvider.notifier).markDeliveryComplete(filename);
          }
        });
      }
    } catch (e) {
      debugPrint('Upload error for ball $ballNumber: $e');
    }
  }

  void _endSession() {
    _sessionActive = false;
    _cameraController?.stopVideoRecording().ignore();
    context.go('/session/results?sessionId=${widget.sessionId ?? ""}');
  }

  @override
  void dispose() {
    _sessionActive = false;
    _isDetectingRunUp = false;
    _poseDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recordingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // -------------------------------------------------------------
          // CALIBRATION PHASE
          // -------------------------------------------------------------
          if (_isCalibrating) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StumpBoxPainter(isLocked: false),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Fit the stumps completely in the boxes,\nthen press LOCK STUMPS.\nPinch to zoom in or out!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _sessionActive = false;
                  context.go('/dashboard');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 50,
              right: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _finishCalibration,
                icon: const Icon(Icons.lock),
                label: const Text('LOCK STUMPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
          // -------------------------------------------------------------
          // RECORDING / TRACKING PHASE
          // -------------------------------------------------------------
          if (!_isCalibrating)
            // Keep the green locked boxes visible during recording
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StumpBoxPainter(isLocked: true),
                ),
              ),
            ),

          // Top HUD
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back/Unlock Button or Status
                GestureDetector(
                  onTap: _unlockCalibration,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                
                // Ball count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/spintrack_logo.png', width: 16, height: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$_ballCount balls',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                _StatusBadge(state: recState, isDetecting: _isDetectingRunUp),
              ],
            ),
          ),

          // Bottom: End Session button (only show once calibrated)
          if (!_isCalibrating)
            Positioned(
              bottom: 50,
              left: 30,
              right: 30,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _endSession,
                icon: const Icon(Icons.stop_circle),
                label: const Text('End Session',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// HELPER FOR STUMP BOXES
// -------------------------------------------------------------
class _StumpBoxPainter extends CustomPainter {
  final bool isLocked;
  _StumpBoxPainter({this.isLocked = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLocked ? Colors.green : Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Striker (far / smaller) - upper portion
    final strikerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.33),
      width: size.width * 0.28,
      height: size.height * 0.22,
    );

    // Non-Striker (near / larger) - lower portion
    final nonStrikerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.68),
      width: size.width * 0.45,
      height: size.height * 0.28,
    );

    // Draw dashed boxes
    _drawDashedRect(canvas, nonStrikerRect, paint);
    _drawDashedRect(canvas, strikerRect, paint);

    // Labels
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      background: Paint()..color = Colors.black54,
    );

    final nonStrikerLabel = TextSpan(text: ' Non-Striker Stumps ', style: textStyle);
    final strikerLabel    = TextSpan(text: ' Striker Stumps ', style: textStyle);

    TextPainter(text: nonStrikerLabel, textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(nonStrikerRect.left, nonStrikerRect.top - 20));

    TextPainter(text: strikerLabel, textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(strikerRect.left, strikerRect.top - 20));
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashLen = 12.0;
    const gapLen  = 6.0;

    void drawDashedLine(Offset start, Offset end) {
      final total = (end - start).distance;
      final dir   = (end - start) / total;
      double d    = 0;
      bool drawing = true;
      while (d < total) {
        final seg = drawing ? dashLen : gapLen;
        final next = d + seg;
        if (drawing) {
          canvas.drawLine(start + dir * d, start + dir * next.clamp(0, total), paint);
        }
        d += seg;
        drawing = !drawing;
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomLeft, rect.bottomRight);
    drawDashedLine(rect.topLeft, rect.bottomLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedRectPainter({
    this.color = Colors.red,
    this.strokeWidth = 2.0,
    this.dashWidth = 10.0,
    this.dashSpace = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, paint, const Offset(0, 0), Offset(size.width, 0));
    _drawDashedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height));
    _drawDashedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height));
    _drawDashedLine(canvas, paint, Offset(0, size.height), const Offset(0, 0));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset p1, Offset p2) {
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    var distance = math.sqrt(dx * dx + dy * dy);
    var dashes = distance / (dashWidth + dashSpace);
    var xSpacing = dx / dashes;
    var ySpacing = dy / dashes;

    for (var i = 0; i < dashes; i++) {
        var start = Offset(p1.dx + xSpacing * i, p1.dy + ySpacing * i);
        var end = Offset(p1.dx + xSpacing * (i + dashWidth / (dashWidth + dashSpace)), 
                         p1.dy + ySpacing * (i + dashWidth / (dashWidth + dashSpace)));
        canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusBadge extends StatelessWidget {
  final RecordingState state;
  final bool isDetecting;
  const _StatusBadge({required this.state, this.isDetecting = false});

  @override
  Widget build(BuildContext context) {
    if (isDetecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_search, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text("WAITING FOR BOWLER",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      );
    }
    
    final (color, icon, label) = switch (state) {
      RecordingState.recording => (Colors.red, Icons.fiber_manual_record, 'RECORDING'),
      RecordingState.uploading => (Colors.orange, Icons.cloud_upload, 'UPLOADING'),
      RecordingState.idle      => (Colors.green, Icons.radio_button_unchecked, 'READY'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
