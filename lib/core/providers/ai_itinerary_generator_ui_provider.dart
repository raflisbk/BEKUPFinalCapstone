import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';

/// Provider untuk mengelola state UI di AI Itinerary Generator Screen
/// Menghindari penggunaan setState
class AIItineraryGeneratorUIProvider extends ChangeNotifier {
  // Form state
  int _days = 3;
  double _budgetPerDay = 100.0;
  final List<String> _selectedInterests = [];
  String _pace = 'moderate';
  int _travelers = 2;

  // Generation state
  bool _isGenerating = false;
  AIItineraryResult? _result;
  String? _error;

  // Getters
  int get days => _days;
  double get budgetPerDay => _budgetPerDay;
  List<String> get selectedInterests => List.unmodifiable(_selectedInterests);
  String get pace => _pace;
  int get travelers => _travelers;
  bool get isGenerating => _isGenerating;
  AIItineraryResult? get result => _result;
  String? get error => _error;

  /// Set number of days
  void setDays(int days) {
    if (_days != days) {
      _days = days;
      notifyListeners();
    }
  }

  /// Set budget per day
  void setBudgetPerDay(double budget) {
    _budgetPerDay = budget;
    notifyListeners();
  }

  /// Toggle interest selection
  void toggleInterest(String interest) {
    if (_selectedInterests.contains(interest)) {
      _selectedInterests.remove(interest);
    } else {
      _selectedInterests.add(interest);
    }
    notifyListeners();
  }

  /// Set travel pace
  void setPace(String pace) {
    if (_pace != pace) {
      _pace = pace;
      notifyListeners();
    }
  }

  /// Set number of travelers
  void setTravelers(int travelers) {
    if (_travelers != travelers) {
      _travelers = travelers;
      notifyListeners();
    }
  }

  /// Set generation state
  void setGenerating(bool generating) {
    if (_isGenerating != generating) {
      _isGenerating = generating;
      notifyListeners();
    }
  }

  /// Set result
  void setResult(AIItineraryResult? result) {
    _result = result;
    _isGenerating = false;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Start generation (set loading state and clear error)
  void startGeneration() {
    _isGenerating = true;
    _error = null;
    notifyListeners();
  }

  /// Reset result to go back to form
  void resetResult() {
    _result = null;
    notifyListeners();
  }

  /// Reset all to initial state
  void reset() {
    _days = 3;
    _budgetPerDay = 100.0;
    _selectedInterests.clear();
    _pace = 'moderate';
    _travelers = 2;
    _isGenerating = false;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
