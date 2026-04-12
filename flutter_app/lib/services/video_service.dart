// lib/services/video_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/analysis_result.dart';

class VideoService {
  final _client = ApiClient().dio;

  /// Saves video to app's local documents directory, then uploads to backend.
  /// Returns map with 'filename' and 'delivery_id' keys.
  Future<Map<String, dynamic>> uploadVideo(String filePath, {int? sessionId}) async {
    // 1. Save video locally (copy to app documents/FullTrackAI folder)
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${docsDir.path}/FullTrackAI');
      await saveDir.create(recursive: true);
      final fileName = 'delivery_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(filePath).copy('${saveDir.path}/$fileName');
      debugPrint('Video saved locally to: ${saveDir.path}/$fileName');
    } catch (e) {
      debugPrint('Failed to save video locally: $e');
    }

    // 2. Upload to backend
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'delivery.mp4',
      ),
      if (sessionId != null) 'session_id': sessionId,
    });

    final response = await _client.post(
      '/video/upload',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Polls trajectory endpoint until data is available (max retries).
  Future<AnalysisResult?> fetchTrajectory(String filename, {int maxRetries = 10}) async {
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final response = await _client.get('/video/trajectory/$filename');
        final data = response.data as Map<String, dynamic>;
        if (!data.containsKey('error')) {
          // Store the analysis report locally
          try {
            final prefs = await SharedPreferences.getInstance();
            final key = 'analysis_$filename';
            await prefs.setString(key, jsonEncode(data));
            debugPrint('Analysis data saved locally for $filename');
          } catch (e) {
            debugPrint('Error saving analysis data: $e');
          }
          return AnalysisResult.fromTrajectoryJson(data);
        }
      } catch (_) {
        // Still processing — continue polling
      }
    }
    return null;
  }
}
