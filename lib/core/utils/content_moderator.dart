import 'logger.dart';

/// Content moderation utility for filtering inappropriate content
class ContentModerator {
  static const String _tag = 'ContentModerator';

  // Profanity and inappropriate words list (Indonesian & English)
  static final List<String> _bannedWords = [
    // Add banned words here - keeping empty for professional code
    // This should be populated based on your moderation policy
  ];

  // Spam patterns
  static final List<RegExp> _spamPatterns = [
    RegExp(r'(https?://)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(/\S*)?', caseSensitive: false), // URLs
    RegExp(r'\d{10,}', caseSensitive: false), // Long numbers (phone numbers)
    RegExp(r'(.)\1{4,}', caseSensitive: false), // Repeated characters (aaaaa)
    RegExp(r'(call|wa|whatsapp|contact|hubungi|telp|telepon).{0,10}\d', caseSensitive: false), // Contact info
  ];

  /// Check if content contains banned words
  static bool containsProfanity(String content) {
    final lowerContent = content.toLowerCase();

    for (var word in _bannedWords) {
      if (lowerContent.contains(word.toLowerCase())) {
        AppLogger.warning(_tag, 'Profanity detected', {
          'word': word,
        });
        return true;
      }
    }

    return false;
  }

  /// Check if content looks like spam
  static bool isSpam(String content) {
    // Check for spam patterns
    for (var pattern in _spamPatterns) {
      if (pattern.hasMatch(content)) {
        AppLogger.warning(_tag, 'Spam pattern detected', {
          'pattern': pattern.pattern,
        });
        return true;
      }
    }

    // Check for excessive capitalization (>80% caps)
    final letters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.isNotEmpty) {
      final capsCount = letters.split('').where((c) => c == c.toUpperCase()).length;
      final capsPercentage = (capsCount / letters.length) * 100;

      if (capsPercentage > 80 && letters.length > 10) {
        AppLogger.warning(_tag, 'Excessive capitalization detected', {
          'percentage': capsPercentage.toStringAsFixed(1),
        });
        return true;
      }
    }

    return false;
  }

  /// Check if content is too short
  static bool isTooShort(String content, {int minLength = 10}) {
    final trimmed = content.trim();
    return trimmed.length < minLength;
  }

  /// Check if content is too long
  static bool isTooLong(String content, {int maxLength = 5000}) {
    return content.length > maxLength;
  }

  /// Comprehensive content validation
  static ModerationResult moderateContent({
    required String content,
    required ContentType type,
    int minLength = 10,
    int maxLength = 5000,
  }) {
    AppLogger.debug(_tag, 'Moderating content', {
      'type': type.name,
      'length': content.length,
    });

    // Check length
    if (isTooShort(content, minLength: minLength)) {
      return ModerationResult(
        isApproved: false,
        reason: 'Content is too short (minimum $minLength characters)',
        action: ModerationAction.reject,
      );
    }

    if (isTooLong(content, maxLength: maxLength)) {
      return ModerationResult(
        isApproved: false,
        reason: 'Content is too long (maximum $maxLength characters)',
        action: ModerationAction.reject,
      );
    }

    // Check for profanity
    if (containsProfanity(content)) {
      return ModerationResult(
        isApproved: false,
        reason: 'Content contains inappropriate language',
        action: ModerationAction.flagForReview,
        severity: ViolationSeverity.medium,
      );
    }

    // Check for spam
    if (isSpam(content)) {
      return ModerationResult(
        isApproved: false,
        reason: 'Content appears to be spam',
        action: ModerationAction.flagForReview,
        severity: ViolationSeverity.low,
      );
    }

    AppLogger.debug(_tag, 'Content approved');

    return ModerationResult(
      isApproved: true,
      reason: 'Content passed moderation',
      action: ModerationAction.approve,
    );
  }

  /// Sanitize user input (remove potentially harmful content)
  static String sanitizeInput(String input) {
    // Remove leading/trailing whitespace
    var sanitized = input.trim();

    // Replace multiple spaces with single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove null bytes
    sanitized = sanitized.replaceAll(RegExp(r'\x00'), '');

    // Remove control characters except newlines and tabs
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Calculate content quality score (0-100)
  static int calculateQualityScore(String content) {
    int score = 50; // Base score

    // Length bonus (sweet spot: 100-500 chars)
    final length = content.trim().length;
    if (length >= 100 && length <= 500) {
      score += 20;
    } else if (length > 50 && length < 100) {
      score += 10;
    } else if (length > 500) {
      score += 5;
    }

    // Sentence structure bonus
    final sentences = content.split(RegExp(r'[.!?]+'));
    if (sentences.length >= 2) {
      score += 10;
    }

    // Proper capitalization bonus
    final hasProperCapitalization = RegExp(r'^[A-Z]').hasMatch(content.trim());
    if (hasProperCapitalization) {
      score += 10;
    }

    // Penalty for excessive capitalization
    final letters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.isNotEmpty) {
      final capsCount = letters.split('').where((c) => c == c.toUpperCase()).length;
      final capsPercentage = (capsCount / letters.length) * 100;
      if (capsPercentage > 50) {
        score -= 15;
      }
    }

    // Penalty for spam indicators
    if (isSpam(content)) {
      score -= 30;
    }

    // Penalty for profanity
    if (containsProfanity(content)) {
      score -= 40;
    }

    return score.clamp(0, 100);
  }

  /// Get content recommendation based on quality score
  static String getRecommendation(int qualityScore) {
    if (qualityScore >= 80) {
      return 'Excellent content!';
    } else if (qualityScore >= 60) {
      return 'Good content, consider adding more details';
    } else if (qualityScore >= 40) {
      return 'Content needs improvement';
    } else {
      return 'Please write more thoughtful content';
    }
  }
}

/// Content moderation result
class ModerationResult {
  final bool isApproved;
  final String reason;
  final ModerationAction action;
  final ViolationSeverity severity;

  ModerationResult({
    required this.isApproved,
    required this.reason,
    required this.action,
    this.severity = ViolationSeverity.none,
  });
}

/// Moderation action to take
enum ModerationAction {
  approve,
  reject,
  flagForReview,
  autoDelete,
}

/// Severity of content violation
enum ViolationSeverity {
  none,
  low,
  medium,
  high,
  critical,
}

/// Type of content being moderated
enum ContentType {
  review,
  comment,
  message,
  bio,
  tripDescription,
  photoCaption,
}

/// Extension for content type display
extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.review:
        return 'Review';
      case ContentType.comment:
        return 'Comment';
      case ContentType.message:
        return 'Message';
      case ContentType.bio:
        return 'Bio';
      case ContentType.tripDescription:
        return 'Trip Description';
      case ContentType.photoCaption:
        return 'Photo Caption';
    }
  }
}
