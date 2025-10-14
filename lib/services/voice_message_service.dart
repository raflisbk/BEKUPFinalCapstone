import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/utils/logger.dart';
import 'cloudinary_service.dart';

/// Voice message model
class VoiceMessage {
  final String id;
  final String url;
  final int durationInSeconds;
  final DateTime timestamp;
  final String senderId;
  final bool isPlayed;

  const VoiceMessage({
    required this.id,
    required this.url,
    required this.durationInSeconds,
    required this.timestamp,
    required this.senderId,
    this.isPlayed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'durationInSeconds': durationInSeconds,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'isPlayed': isPlayed,
    };
  }

  factory VoiceMessage.fromMap(Map<String, dynamic> map) {
    return VoiceMessage(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      durationInSeconds: map['durationInSeconds'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      senderId: map['senderId'] ?? '',
      isPlayed: map['isPlayed'] ?? false,
    );
  }
}

/// Service for voice message recording and playback
class VoiceMessageService {
  static const String _tag = 'VoiceMessageService';

  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Recording state
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  int get currentRecordingDuration {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Start recording voice message
  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        AppLogger.warning(_tag, 'Already recording');
        return false;
      }

      AppLogger.info(_tag, 'Starting voice recording');

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_$timestamp.m4a';

      // In real implementation, use flutter_sound or record package:
      // await _recorder.startRecorder(
      //   toFile: _currentRecordingPath,
      //   codec: Codec.aacMP4,
      // );

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      AppLogger.success(_tag, 'Voice recording started', {
        'path': _currentRecordingPath,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start recording', e, stackTrace);
      _isRecording = false;
      _recordingStartTime = null;
      return false;
    }
  }

  /// Stop recording and get file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        AppLogger.warning(_tag, 'Not currently recording');
        return null;
      }

      AppLogger.info(_tag, 'Stopping voice recording');

      // In real implementation:
      // await _recorder.stopRecorder();

      final recordingPath = _currentRecordingPath;
      final duration = currentRecordingDuration;

      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;

      AppLogger.success(_tag, 'Voice recording stopped', {
        'duration': duration,
        'path': recordingPath,
      });

      return recordingPath;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop recording', e, stackTrace);
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;

      AppLogger.info(_tag, 'Cancelling voice recording');

      // In real implementation:
      // await _recorder.stopRecorder();

      // Delete the file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;

      AppLogger.success(_tag, 'Voice recording cancelled');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel recording', e, stackTrace);
    }
  }

  /// Upload voice message to Cloudinary
  Future<VoiceMessage?> uploadVoiceMessage({
    required File audioFile,
    required String chatRoomId,
    required String senderId,
  }) async {
    try {
      AppLogger.info(_tag, 'Uploading voice message', {
        'chatRoomId': chatRoomId,
        'fileSize': await audioFile.length(),
      });

      // Get audio duration (mock for now)
      // In real implementation, use audio metadata package
      const duration = 10; // Mock duration

      // Upload to Cloudinary
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${senderId}_$timestamp';
      
      final downloadUrl = await _cloudinaryService.uploadFile(
        file: audioFile,
        folder: 'voice_messages/$chatRoomId',
        fileName: fileName,
        resourceType: 'video', // Cloudinary uses 'video' for audio files
      );

      // Delete local file
      await audioFile.delete();

      final voiceMessage = VoiceMessage(
        id: timestamp.toString(),
        url: downloadUrl,
        durationInSeconds: duration,
        timestamp: DateTime.now(),
        senderId: senderId,
      );

      AppLogger.success(_tag, 'Voice message uploaded to Cloudinary', {
        'url': downloadUrl,
        'duration': duration,
      });

      return voiceMessage;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload voice message', e, stackTrace);
      return null;
    }
  }

  /// Play voice message
  Future<bool> playVoiceMessage(String url) async {
    try {
      AppLogger.info(_tag, 'Playing voice message', {
        'url': url,
      });

      // In real implementation, use audioplayers or just_audio package:
      // await _player.play(UrlSource(url));

      AppLogger.success(_tag, 'Voice message playing');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to play voice message', e, stackTrace);
      return false;
    }
  }

  /// Pause voice message playback
  Future<void> pauseVoiceMessage() async {
    try {
      AppLogger.debug(_tag, 'Pausing voice message');

      // In real implementation:
      // await _player.pause();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to pause voice message', e, stackTrace);
    }
  }

  /// Stop voice message playback
  Future<void> stopVoiceMessage() async {
    try {
      AppLogger.debug(_tag, 'Stopping voice message');

      // In real implementation:
      // await _player.stop();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop voice message', e, stackTrace);
    }
  }

  /// Get audio duration from file
  Future<int> getAudioDuration(String filePath) async {
    try {
      // In real implementation, use audio metadata package
      // For now, return mock duration
      return 10;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get audio duration', e, stackTrace);
      return 0;
    }
  }

  /// Check microphone permission
  Future<bool> hasMicrophonePermission() async {
    try {
      AppLogger.debug(_tag, 'Checking microphone permission');

      // In real implementation, use permission_handler package:
      // final status = await Permission.microphone.status;
      // return status.isGranted;

      return true; // Mock
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check microphone permission', e, stackTrace);
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      AppLogger.info(_tag, 'Requesting microphone permission');

      // In real implementation:
      // final status = await Permission.microphone.request();
      // return status.isGranted;

      return true; // Mock
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to request microphone permission', e, stackTrace);
      return false;
    }
  }

  /// Compress audio file (reduce file size)
  Future<File?> compressAudio(File audioFile) async {
    try {
      AppLogger.info(_tag, 'Compressing audio file', {
        'originalSize': await audioFile.length(),
      });

      // In real implementation, use ffmpeg or similar
      // For now, return the original file
      return audioFile;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to compress audio', e, stackTrace);
      return null;
    }
  }

  /// Generate waveform data for visualization
  Future<List<double>> generateWaveform(String filePath) async {
    try {
      AppLogger.debug(_tag, 'Generating waveform', {
        'filePath': filePath,
      });

      // In real implementation, analyze audio file and generate waveform data
      // For now, return mock waveform
      return List.generate(50, (index) => (index % 5) / 5.0);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate waveform', e, stackTrace);
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    // In real implementation:
    // _recorder.closeRecorder();
    // _player.dispose();
    AppLogger.debug(_tag, 'Disposing voice message service');
  }
}
