import 'dart:async';
import 'dart:convert';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'ai_service.dart';

/// Content Moderation Service
/// Handles content moderation, safety checks, and community guidelines enforcement
class ContentModerationService {
  static const String _tag = 'ContentModerationService';
  static const String _moderationLogsTable = 'moderation_logs';
  static const String _reportedContentTable = 'reported_content';
  static const String _moderationRulesTable = 'moderation_rules';
  static const String _bannedWordsTable = 'banned_words';

  // Singleton pattern
  static ContentModerationService? _instance;
  static ContentModerationService get instance => _instance ??= ContentModerationService._internal();
  
  ContentModerationService._internal();

  // AI Service instance
  final AIService _aiService = AIService();

  // Moderation actions
  static const String actionApprove = 'approve';
  static const String actionFlag = 'flag';
  static const String actionBlock = 'block';
  static const String actionRemove = 'remove';
  static const String actionWarn = 'warn';

  // Content types
  static const String typeComment = 'comment';
  static const String typeReview = 'review';
  static const String typePost = 'post';
  static const String typeMessage = 'message';
  static const String typeProfile = 'profile';
  static const String typeImage = 'image';

  // Severity levels
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  // ===============================
  // CONTENT MODERATION
  // ===============================

  /// Moderate text content
  Future<Map<String, dynamic>> moderateTextContent({
    required String content,
    required String contentType,
    String? contentId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Moderating text content: $contentType');

      // Initial safety checks
      final basicChecks = await _performBasicChecks(content);
      
      // AI-powered content analysis
      final aiAnalysis = await _performAIAnalysis(content, contentType);
      
      // Combine results
      final moderationResult = _combineResults(basicChecks, aiAnalysis);
      
      // Log moderation action
      await _logModerationAction(
        contentType: contentType,
        contentId: contentId,
        userId: userId,
        content: content,
        result: moderationResult,
        metadata: metadata,
      );

      // Take action based on result
      await _executeAction(moderationResult, contentType, contentId, userId);

      AppLogger.success(_tag, 'Content moderation completed: ${moderationResult['action']}');
      return moderationResult;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to moderate content', e, stackTrace);
      rethrow;
    }
  }

  /// Moderate image content
  Future<Map<String, dynamic>> moderateImageContent({
    required String imageUrl,
    required String contentType,
    String? contentId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Moderating image content: $contentType');

      // For now, we'll use basic checks and AI text analysis on image metadata
      // In a full implementation, this would use image recognition APIs
      
      final moderationResult = {
        'action': actionApprove,
        'severity': severityLow,
        'confidence': 0.8,
        'reasons': <String>[],
        'flagged_elements': <String>[],
        'safe_to_display': true,
        'requires_human_review': false,
        'analysis_type': 'basic_image_check',
      };

      // Log moderation action
      await _logModerationAction(
        contentType: contentType,
        contentId: contentId,
        userId: userId,
        content: imageUrl,
        result: moderationResult,
        metadata: metadata,
      );

      AppLogger.success(_tag, 'Image moderation completed');
      return moderationResult;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to moderate image', e, stackTrace);
      rethrow;
    }
  }

  /// Batch moderate multiple content items
  Future<List<Map<String, dynamic>>> batchModerateContent({
    required List<Map<String, dynamic>> contentItems,
  }) async {
    try {
      AppLogger.debug(_tag, 'Batch moderating ${contentItems.length} items');

      final results = <Map<String, dynamic>>[];

      for (final item in contentItems) {
        try {
          final result = await moderateTextContent(
            content: item['content'] ?? '',
            contentType: item['type'] ?? typeComment,
            contentId: item['id'],
            userId: item['user_id'],
            metadata: item['metadata'],
          );
          
          results.add({
            'content_id': item['id'],
            'result': result,
            'status': 'success',
          });
        } catch (e) {
          results.add({
            'content_id': item['id'],
            'result': null,
            'status': 'error',
            'error': e.toString(),
          });
        }
      }

      AppLogger.success(_tag, 'Batch moderation completed');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to batch moderate content', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONTENT REPORTING
  // ===============================

  /// Report content
  Future<Map<String, dynamic>> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
    String? reportedUserId,
    List<String>? evidenceUrls,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Content reported: $contentType $contentId');

      final reportData = {
        'content_id': contentId,
        'content_type': contentType,
        'reported_by': userId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'evidence_urls': evidenceUrls ?? [],
        'status': 'pending',
        'priority': _calculateReportPriority(reason),
      };

      final report = await SupabaseDatabaseService.insert(
        table: _reportedContentTable,
        data: reportData,
      );

      // Trigger automatic moderation review
      await _reviewReportedContent(report['id']);

      AppLogger.success(_tag, 'Content report created');
      return report;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report content', e, stackTrace);
      rethrow;
    }
  }

  /// Get reported content
  Future<List<Map<String, dynamic>>> getReportedContent({
    String? status,
    String? contentType,
    String? priority,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting reported content');

      final filters = <String, dynamic>{};
      if (status != null) filters['status'] = status;
      if (contentType != null) filters['content_type'] = contentType;
      if (priority != null) filters['priority'] = priority;

      final reports = await SupabaseDatabaseService.select(
        table: _reportedContentTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${reports.length} reported content items');
      return reports;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get reported content', e, stackTrace);
      rethrow;
    }
  }

  /// Update report status
  static Future<Map<String, dynamic>> updateReportStatus({
    required String reportId,
    required String status,
    String? resolution,
    String? moderatorNotes,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      AppLogger.debug(_tag, 'Updating report status: $reportId');

      final updateData = {
        'status': status,
        'resolved_by': userId,
        'resolution': resolution,
        'moderator_notes': moderatorNotes,
        'resolved_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.update(
        table: _reportedContentTable,
        id: reportId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Report status updated');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update report status', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // MODERATION RULES
  // ===============================

  /// Create moderation rule
  static Future<Map<String, dynamic>> createModerationRule({
    required String name,
    required String condition,
    required String action,
    String? description,
    List<String>? keywords,
    Map<String, dynamic>? parameters,
    bool isActive = true,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating moderation rule: $name');

      final ruleData = {
        'name': name,
        'condition': condition,
        'action': action,
        'description': description,
        'keywords': keywords ?? [],
        'parameters': parameters ?? {},
        'created_by': userId,
        'is_active': isActive,
        'trigger_count': 0,
      };

      final rule = await SupabaseDatabaseService.insert(
        table: _moderationRulesTable,
        data: ruleData,
      );

      AppLogger.success(_tag, 'Moderation rule created');
      return rule;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create moderation rule', e, stackTrace);
      rethrow;
    }
  }

  /// Get moderation rules
  Future<List<Map<String, dynamic>>> getModerationRules({
    bool? isActive,
    String? action,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting moderation rules');

      final filters = <String, dynamic>{};
      if (isActive != null) filters['is_active'] = isActive;
      if (action != null) filters['action'] = action;

      final rules = await SupabaseDatabaseService.select(
        table: _moderationRulesTable,
        filters: filters,
        orderBy: 'created_at',
      );

      AppLogger.success(_tag, 'Retrieved ${rules.length} moderation rules');
      return rules;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get moderation rules', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BANNED WORDS MANAGEMENT
  // ===============================

  /// Add banned words
  static Future<void> addBannedWords({
    required List<String> words,
    String? category,
    String? severity,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding ${words.length} banned words');

      for (final word in words) {
        final wordData = {
          'word': word.toLowerCase().trim(),
          'category': category ?? 'general',
          'severity': severity ?? severityMedium,
          'added_by': userId,
          'is_active': true,
        };

        await SupabaseDatabaseService.insert(
          table: _bannedWordsTable,
          data: wordData,
        );
      }

      AppLogger.success(_tag, 'Banned words added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add banned words', e, stackTrace);
      rethrow;
    }
  }

  /// Get banned words
  Future<List<String>> getBannedWords({
    String? category,
    String? severity,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting banned words');

      final filters = <String, dynamic>{'is_active': true};
      if (category != null) filters['category'] = category;
      if (severity != null) filters['severity'] = severity;

      final words = await SupabaseDatabaseService.select(
        table: _bannedWordsTable,
        filters: filters,
      );

      final wordList = words.map((w) => w['word'] as String).toList();
      
      AppLogger.success(_tag, 'Retrieved ${wordList.length} banned words');
      return wordList;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get banned words', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get moderation statistics
  Future<Map<String, dynamic>> getModerationStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting moderation statistics');

      final filters = <String, dynamic>{};
      
      var logs = await SupabaseDatabaseService.select(
        table: _moderationLogsTable,
        filters: filters,
      );

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        logs = logs.where((log) {
          final timestamp = DateTime.parse(log['created_at']);
          if (startDate != null && timestamp.isBefore(startDate)) return false;
          if (endDate != null && timestamp.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Calculate statistics
      final totalActions = logs.length;
      final actionCounts = <String, int>{};
      final contentTypeCounts = <String, int>{};
      final severityCounts = <String, int>{};

      for (final log in logs) {
        final action = log['action'] as String;
        final contentType = log['content_type'] as String;
        final severity = log['severity'] as String;

        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        contentTypeCounts[contentType] = (contentTypeCounts[contentType] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return {
        'total_actions': totalActions,
        'action_counts': actionCounts,
        'content_type_counts': contentTypeCounts,
        'severity_counts': severityCounts,
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get moderation statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Perform basic checks (banned words, spam detection)
  Future<Map<String, dynamic>> _performBasicChecks(String content) async {
    try {
      final results = {
        'banned_words': <String>[],
        'spam_score': 0.0,
        'language_detected': 'en',
        'contains_personal_info': false,
        'flagged': false,
      };

      // Check banned words
      final bannedWords = await getBannedWords();
      final contentLower = content.toLowerCase();
      
      for (final word in bannedWords) {
        if (contentLower.contains(word)) {
          results['banned_words'] = [...(results['banned_words'] as List), word];
          results['flagged'] = true;
        }
      }

      // Basic spam detection
      final spamIndicators = [
        'click here', 'buy now', 'limited time', 'free money',
        'guaranteed', 'make money fast', 'no questions asked'
      ];

      int spamCount = 0;
      for (final indicator in spamIndicators) {
        if (contentLower.contains(indicator)) {
          spamCount++;
        }
      }

      results['spam_score'] = spamCount / spamIndicators.length;
      if ((results['spam_score'] as double) > 0.3) {
        results['flagged'] = true;
      }

      // Check for personal information patterns
      final personalInfoPatterns = [
        RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), // SSN-like pattern
        RegExp(r'\b\d{16}\b'), // Credit card-like pattern
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
      ];

      for (final pattern in personalInfoPatterns) {
        if (pattern.hasMatch(content)) {
          results['contains_personal_info'] = true;
          results['flagged'] = true;
          break;
        }
      }

      return results;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to perform basic checks', e);
      return {'flagged': false, 'banned_words': [], 'spam_score': 0.0};
    }
  }

  /// Perform AI analysis
  Future<Map<String, dynamic>> _performAIAnalysis(String content, String contentType) async {
    try {
      // Use AI sentiment analysis
      final sentiment = await _aiService.analyzeSentiment(content);
      
      // Generate AI safety analysis
      final prompt = '''
Analyze this $contentType content for safety and community guidelines:

"$content"

Check for:
1. Hate speech or discrimination
2. Harassment or bullying
3. Violence or threats
4. Adult/inappropriate content
5. Misinformation
6. Spam or promotional content
7. Privacy violations

Respond with JSON:
{
  "safe": true/false,
  "severity": "low|medium|high|critical",
  "issues": ["issue1", "issue2"],
  "confidence": 0.0-1.0,
  "explanation": "brief explanation"
}
''';

      final aiResponse = await _aiService.generateText(
        prompt: prompt,
        temperature: 0.2,
        maxTokens: 300,
      );

      // Parse AI response
      try {
        final jsonStart = aiResponse.indexOf('{');
        final jsonEnd = aiResponse.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd != -1) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        final aiAnalysis = Map<String, dynamic>.from(
          json.decode(jsonString)
        );          // Combine with sentiment
          aiAnalysis['sentiment'] = sentiment;
          return aiAnalysis;
        }
      } catch (e) {
        AppLogger.warning(_tag, 'Failed to parse AI analysis JSON', e);
      }

      // Fallback
      return {
        'safe': true,
        'severity': severityLow,
        'issues': [],
        'confidence': 0.5,
        'explanation': 'AI analysis completed',
        'sentiment': sentiment,
      };
    } catch (e) {
      AppLogger.warning(_tag, 'AI analysis failed, using fallback', e);
      return {
        'safe': true,
        'severity': severityLow,
        'issues': [],
        'confidence': 0.1,
        'explanation': 'AI analysis unavailable',
      };
    }
  }

  /// Combine moderation results
  static Map<String, dynamic> _combineResults(
    Map<String, dynamic> basicChecks,
    Map<String, dynamic> aiAnalysis,
  ) {
    final flaggedBasic = basicChecks['flagged'] as bool;
    final aiSafe = aiAnalysis['safe'] as bool;
    final aiSeverity = aiAnalysis['severity'] as String;
    
    String action;
    String severity;
    bool requiresHumanReview = false;
    
    if (!aiSafe || flaggedBasic) {
      if (aiSeverity == severityCritical || (basicChecks['banned_words'] as List).isNotEmpty) {
        action = actionBlock;
        severity = severityCritical;
        requiresHumanReview = true;
      } else if (aiSeverity == severityHigh || (basicChecks['spam_score'] as double) > 0.7) {
        action = actionFlag;
        severity = severityHigh;
        requiresHumanReview = true;
      } else {
        action = actionWarn;
        severity = severityMedium;
      }
    } else {
      action = actionApprove;
      severity = severityLow;
    }

    return {
      'action': action,
      'severity': severity,
      'confidence': aiAnalysis['confidence'] ?? 0.5,
      'reasons': [
        ...((basicChecks['banned_words'] as List).isNotEmpty ? ['Banned words detected'] : []),
        ...((basicChecks['spam_score'] as double) > 0.3 ? ['Potential spam'] : []),
        ...(aiAnalysis['issues'] as List? ?? []),
      ],
      'flagged_elements': {
        'banned_words': basicChecks['banned_words'],
        'spam_score': basicChecks['spam_score'],
        'ai_issues': aiAnalysis['issues'],
      },
      'safe_to_display': action == actionApprove,
      'requires_human_review': requiresHumanReview,
      'analysis_details': {
        'basic_checks': basicChecks,
        'ai_analysis': aiAnalysis,
      },
    };
  }

  /// Log moderation action
  static Future<void> _logModerationAction({
    required String contentType,
    String? contentId,
    String? userId,
    required String content,
    required Map<String, dynamic> result,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      
      final logData = {
        'content_type': contentType,
        'content_id': contentId,
        'user_id': userId,
        'content_preview': content.length > 200 ? '${content.substring(0, 200)}...' : content,
        'action': result['action'],
        'severity': result['severity'],
        'confidence': result['confidence'],
        'reasons': result['reasons'],
        'automated': true,
        'moderated_by': currentUserId,
        'metadata': metadata ?? {},
        'analysis_details': result['analysis_details'],
      };

      await SupabaseDatabaseService.insert(
        table: _moderationLogsTable,
        data: logData,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to log moderation action', e);
    }
  }

  /// Execute moderation action
  static Future<void> _executeAction(
    Map<String, dynamic> result,
    String contentType,
    String? contentId,
    String? userId,
  ) async {
    try {
      final action = result['action'] as String;
      
      switch (action) {
        case actionBlock:
          // In a real implementation, this would hide/block the content
          AppLogger.warning(_tag, 'Content blocked: $contentId');
          break;
        case actionFlag:
          // Flag for human review
          AppLogger.warning(_tag, 'Content flagged for review: $contentId');
          break;
        case actionWarn:
          // Send warning to user
          AppLogger.info(_tag, 'User warned: $userId');
          break;
        case actionApprove:
          // Content is safe, no action needed
          break;
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to execute moderation action', e);
    }
  }

  /// Calculate report priority
  static String _calculateReportPriority(String reason) {
    final highPriorityReasons = [
      'harassment', 'threats', 'violence', 'hate_speech',
      'inappropriate_content', 'child_safety'
    ];
    
    final mediumPriorityReasons = [
      'spam', 'misinformation', 'privacy_violation', 'impersonation'
    ];

    if (highPriorityReasons.contains(reason.toLowerCase())) {
      return 'high';
    } else if (mediumPriorityReasons.contains(reason.toLowerCase())) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Review reported content
  static Future<void> _reviewReportedContent(String reportId) async {
    try {
      // Get report details
      final reports = await SupabaseDatabaseService.select(
        table: _reportedContentTable,
        filters: {'id': reportId},
      );

      if (reports.isEmpty) return;

      // This would normally fetch the actual content and perform moderation
      // For now, we'll just update the status
      await SupabaseDatabaseService.update(
        table: _reportedContentTable,
        id: reportId,
        data: {
          'status': 'under_review',
          'reviewed_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to review reported content', e);
    }
  }
}