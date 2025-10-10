import 'package:flutter/foundation.dart';
import '../../services/ai/ai_recommendation_service.dart';

/// Provider untuk mengelola state UI di AI Recommendations Screen
/// Menghindari penggunaan setState
class AIRecommendationsUIProvider extends ChangeNotifier {
  List<DestinationRecommendation>? _personalizedRecs;
  List<DestinationRecommendation>? _trendingRecs;
  bool _isLoading = true;
  String? _error;

  List<DestinationRecommendation>? get personalizedRecs => _personalizedRecs;
  List<DestinationRecommendation>? get trendingRecs => _trendingRecs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Set personalized recommendations
  void setPersonalizedRecs(List<DestinationRecommendation>? recs) {
    _personalizedRecs = recs;
    notifyListeners();
  }

  /// Set trending recommendations
  void setTrendingRecs(List<DestinationRecommendation>? recs) {
    _trendingRecs = recs;
    notifyListeners();
  }

  /// Set both recommendations at once
  void setRecommendations({
    List<DestinationRecommendation>? personalized,
    List<DestinationRecommendation>? trending,
    bool loading = false,
  }) {
    _personalizedRecs = personalized;
    _trendingRecs = trending;
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Reset to initial state
  void reset() {
    _personalizedRecs = null;
    _trendingRecs = null;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
