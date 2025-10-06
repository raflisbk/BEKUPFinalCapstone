import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _tag = 'OnboardingScreen';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Find Your\nTravel Companion',
      description: 'Connect with fellow travelers nearby and share unforgettable adventures together.',
      icon: Icons.people_outline,
    ),
    OnboardingData(
      title: 'Discover Local\nGuides',
      description: 'Experience authentic culture with verified local guides who know the hidden gems.',
      icon: Icons.explore_outlined,
    ),
    OnboardingData(
      title: 'Plan & Budget\nYour Journey',
      description: 'Organize your trip with smart budgeting tools and personalized recommendations.',
      icon: Icons.map_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Onboarding screen initialized', {
      'totalPages': _pages.length,
    });
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing onboarding screen resources');
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    AppLogger.action('User tapped "Skip" button', {
                      'skippedPage': _currentPage + 1,
                    });
                    _navigateToAuth();
                  },
                  child: Text(
                    'Skip',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  AppLogger.action('User swiped to onboarding page ${index + 1}', {
                    'page': index + 1,
                    'title': _pages[index].title.replaceAll('\n', ' '),
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.black,
                      dotColor: AppColors.grey300,
                      expansionFactor: 4,
                      spacing: 8,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Next/Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          AppLogger.action('User tapped "Get Started" button');
                          _navigateToAuth();
                        } else {
                          AppLogger.action('User tapped "Next" button', {
                            'currentPage': _currentPage + 1,
                            'nextPage': _currentPage + 2,
                          });
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAuth() async {
    // Set flag that user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    AppLogger.navigation(_tag, '/auth', {'completedOnboarding': true});
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container - Minimalist geometric design
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.black,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: 80,
                  color: AppColors.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),

          // Title
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Text(
              data.title,
              style: AppTextStyles.displaySmall.copyWith(
                fontSize: 42,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Description
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: Text(
              data.description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
