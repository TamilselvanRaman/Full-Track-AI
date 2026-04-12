// lib/screens/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants.dart';
import '../../models/analysis_result.dart';
import '../../services/video_service.dart';
import '../../widgets/common/stat_overlay_card.dart';
import '../../widgets/analytics/pitchmap_painter.dart';
import '../../widgets/analytics/beehive_painter.dart';
import '../../widgets/analytics/release_point_painter.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String filename;
  final int? deliveryId;

  const ResultsScreen({super.key, required this.filename, this.deliveryId});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  AnalysisResult? _result;
  bool _loadingAnalysis = true;
  bool _videoInitialized = false;

  final _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // Fetch trajectory/analysis from backend
    final result = await _videoService.fetchTrajectory(widget.filename);
    if (mounted) setState(() {
      _result = result;
      _loadingAnalysis = false;
    });

    // Initialize video player using the backend URL
    final videoUrl =
        '${AppConstants.baseUrl.replaceAll('/api/v1', '')}/videos/${widget.filename}';
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _videoController!.initialize();
      if (mounted) setState(() => _videoInitialized = true);
      _videoController!.setLooping(true);
      _videoController!.play();
    } catch (_) {
      // Video may not be served - graceful fallback
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Video Tab ────────────────────────────────────────────────────────
  Widget _buildVideoTab() {
    return Column(
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _videoInitialized
              ? _videoController!.value.aspectRatio
              : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_videoInitialized)
                VideoPlayer(_videoController!)
              else
                Container(
                  color: const Color(AppConstants.surfaceColorValue),
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppConstants.primaryColorValue))),
                ),

              // Speed overlay
              if (_result != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatOverlayCard(
                    label: 'SPEED',
                    value: _result!.speed?.toStringAsFixed(1) ?? '--',
                    unit: 'km/h',
                    color: const Color(AppConstants.primaryColorValue),
                  ),
                ),

              // Swing overlay
              if (_result != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatOverlayCard(
                    label: 'SWING',
                    value: _result!.swing?.toStringAsFixed(1) ?? '--',
                    unit: '°',
                    color: Colors.orangeAccent,
                  ),
                ),

              // Play/Pause tap overlay
              if (_videoInitialized)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: AnimatedOpacity(
                    opacity: _videoController!.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 60, color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Stats row
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(label: 'Line',   value: _result?.line ?? '--'),
              _StatBox(label: 'Length', value: _result?.length ?? '--'),
              _StatBox(
                  label: 'Swing',
                  value: _result?.swing != null
                      ? '${_result!.swing!.toStringAsFixed(1)}°'
                      : '--'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Analytics Tab ────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(AppConstants.primaryColorValue),
            labelColor: Color(AppConstants.primaryColorValue),
            unselectedLabelColor: Color(AppConstants.textSecondaryValue),
            tabs: [
              Tab(text: 'Pitchmap'),
              Tab(text: 'Beehive'),
              Tab(text: 'Release'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Pitchmap
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(AppConstants.cardBgColorValue),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: PitchmapPainter(result: _result),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),

                // Beehive
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(AppConstants.cardBgColorValue),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: BeehivePainter(result: _result),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),

                // Release Points
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(AppConstants.cardBgColorValue),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: ReleasePointPainter(result: _result),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery ${widget.deliveryId ?? ""} Analysis'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppConstants.primaryColorValue),
          labelColor: const Color(AppConstants.primaryColorValue),
          unselectedLabelColor: const Color(AppConstants.textSecondaryValue),
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Video'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
          ],
        ),
      ),
      body: _loadingAnalysis
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Color(AppConstants.primaryColorValue)),
                  SizedBox(height: 16),
                  Text('Loading analysis...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(child: _buildVideoTab()),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColorValue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(AppConstants.textSecondaryValue), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
