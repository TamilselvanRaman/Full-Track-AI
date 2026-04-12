// lib/providers/recording_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecordingState { idle, recording, uploading }

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier() : super(RecordingState.idle);

  void setIdle()      => state = RecordingState.idle;
  void setRecording() => state = RecordingState.recording;
  void setUploading() => state = RecordingState.uploading;
}

final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>(
  (_) => RecordingNotifier(),
);
