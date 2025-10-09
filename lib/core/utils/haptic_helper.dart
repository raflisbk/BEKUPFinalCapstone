import 'package:flutter/services.dart';
import 'logger.dart';

/// Haptic feedback helper for tactile responses
/// Provides consistent haptic feedback across the app
class HapticHelper {
  static const String _tag = 'HapticHelper';

  /// Light impact - for subtle interactions (switches, toggles)
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
      AppLogger.debug(_tag, 'Light haptic feedback triggered');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger light haptic', {'error': e.toString()});
    }
  }

  /// Medium impact - for standard interactions (buttons, cards)
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
      AppLogger.debug(_tag, 'Medium haptic feedback triggered');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger medium haptic', {'error': e.toString()});
    }
  }

  /// Heavy impact - for important actions (submit, delete)
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
      AppLogger.debug(_tag, 'Heavy haptic feedback triggered');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger heavy haptic', {'error': e.toString()});
    }
  }

  /// Selection click - for picker/selector changes
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
      AppLogger.debug(_tag, 'Selection haptic feedback triggered');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger selection haptic', {'error': e.toString()});
    }
  }

  /// Vibrate - for notifications and alerts
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
      AppLogger.debug(_tag, 'Vibrate haptic feedback triggered');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger vibrate', {'error': e.toString()});
    }
  }

  /// Success feedback - combination of light impact for success
  static Future<void> success() async {
    await lightImpact();
  }

  /// Error feedback - combination of heavy impact for errors
  static Future<void> error() async {
    await heavyImpact();
  }

  /// Warning feedback - combination of medium impact for warnings
  static Future<void> warning() async {
    await mediumImpact();
  }

  /// Button tap feedback - standard button press
  static Future<void> buttonTap() async {
    await lightImpact();
  }

  /// Card tap feedback - for card selections
  static Future<void> cardTap() async {
    await lightImpact();
  }

  /// Toggle feedback - for switches and checkboxes
  static Future<void> toggle() async {
    await selectionClick();
  }

  /// Delete feedback - for delete actions
  static Future<void> delete() async {
    await heavyImpact();
  }

  /// Submit feedback - for form submissions
  static Future<void> submit() async {
    await mediumImpact();
  }

  /// Swipe feedback - for swipe gestures
  static Future<void> swipe() async {
    await selectionClick();
  }

  /// Long press feedback - for long press actions
  static Future<void> longPress() async {
    await mediumImpact();
  }
}
