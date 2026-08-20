import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final List<OnboardingItem> _items = [
    OnboardingItem(
      image: 'assets/images/sweetmonk.png',
      isImage: true,
      badge: 'PREMIUM PRODUCT',
      badgeColor: const Color(0xFFF2994A),
      title1: 'Natural Purity.\n',
      highlightText: 'Sweet Monk.',
      title2: '',
      highlightColor: const Color(0xFFF2994A),
      description: 'The purest monk fruit sweetener on the planet. Zero calories, zero spike, 100% natural joy.',
      gradientColors: [const Color(0xFFFFFBF4), const Color(0xFFF3E2CC)],
      textColor: const Color(0xFF132039),
      buttonColor: const Color(0xFF132039),
    ),
    OnboardingItem(
      badge: 'AI TECHNOLOGY',
      badgeColor: const Color(0xFF38B6FF),
      title1: 'Vision-Based\n',
      highlightText: 'Plate Scanning.',
      title2: '',
      highlightColor: const Color(0xFF38B6FF),
      description: 'Point your camera at your food. Our AI instantly breaks down nutrition, GI, and health scores.',
      gradientColors: [const Color(0xFF0D254C), const Color(0xFF050D1A)],
      textColor: Colors.white,
      buttonColor: Colors.white,
      isDark: true,
    ),
    OnboardingItem(
      badge: 'SMART HUB',
      badgeColor: const Color(0xFF27AE60),
      title1: 'Connect with a\n',
      highlightText: 'Global Circle.',
      title2: '',
      highlightColor: const Color(0xFF219653),
      description: 'Join a community that understands you. Share recipes and stay on track with smart social tools.',
      gradientColors: [const Color(0xFFF3FAF4), const Color(0xFFD0EBD5)],
      textColor: const Color(0xFF103322),
      buttonColor: const Color(0xFF1E824C),
    ),
  ];

  Widget _buildVisualContent(int index) {
    if (index == 0) {
      // Real Product Image for Slide 1
      return Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF2994A).withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/sweetmonk.png',
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (index == 1) {
      // AI Scanning Visual Illustration
      return Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF38B6FF).withValues(alpha: 0.4), width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Scanning Grid
                  Opacity(
                    opacity: 0.1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                      itemBuilder: (c, i) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  // Animated Scanning Bar
                  Positioned(
                    top: 260 * _animationController.value,
                    left: 0, right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38B6FF),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38B6FF).withValues(alpha: 0.8), 
                            blurRadius: 15, 
                            spreadRadius: 2
                          )
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.center_focus_strong_outlined, size: 80, color: Color(0xFF38B6FF)),
                  // UI "Dots"
                  ...List.generate(4, (i) {
                    double angle = (i * 90) * math.pi / 180;
                    return Transform.translate(
                      offset: Offset(math.cos(angle) * 110, math.sin(angle) * 110),
                      child: Container(width: 8, height: 8, color: const Color(0xFF38B6FF)),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Smart Community / Network Visual
      return Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Connecting lines effect
                ...List.generate(8, (i) {
                  double angle = (i * 45) * math.pi / 180;
                  return Transform.rotate(
                    angle: angle + (_animationController.value * math.pi * 0.5),
                    child: Container(
                      width: 220,
                      height: 1,
                      color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.people_outline, size: 100, color: Color(0xFF27AE60)),
                ),
                ...List.generate(6, (i) {
                  double angle = (i * 60 + 30) * math.pi / 180;
                  double dist = 100 + (10 * math.sin(_animationController.value * math.pi * 2 + i));
                  return Transform.translate(
                    offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 20, color: const Color(0xFF27AE60).withValues(alpha: 0.6)),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: currentItem.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: currentItem.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32), size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Kosmico',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: currentItem.textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: currentItem.isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(color: currentItem.textColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Illustration / Product Image
                          SizedBox(height: 320, child: _buildVisualContent(index)),
                          const SizedBox(height: 40),

                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: item.badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.badge,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Title with Highlights
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: item.textColor, height: 1.15, letterSpacing: -0.5),
                              children: [
                                TextSpan(text: item.title1),
                                TextSpan(text: item.highlightText, style: TextStyle(color: item.highlightColor)),
                                TextSpan(text: item.title2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Description
                          Text(
                            item.description,
                            style: TextStyle(fontSize: 16, color: item.textColor.withValues(alpha: 0.75), height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Indicators
                    Row(
                      children: List.generate(_items.length, (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? currentItem.highlightColor : currentItem.textColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),

                    // Action Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _items.length - 1) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        } else {
                          _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentItem.buttonColor,
                        foregroundColor: currentItem.isDark ? const Color(0xFF0D254C) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String? image;
  final bool isImage;
  final String badge;
  final Color badgeColor;
  final String title1;
  final String highlightText;
  final String title2;
  final Color highlightColor;
  final String description;
  final List<Color> gradientColors;
  final Color textColor;
  final Color buttonColor;
  final bool isDark;

  OnboardingItem({
    this.image,
    this.isImage = false,
    required this.badge,
    required this.badgeColor,
    required this.title1,
    required this.highlightText,
    required this.title2,
    required this.highlightColor,
    required this.description,
    required this.gradientColors,
    required this.textColor,
    required this.buttonColor,
    this.isDark = false,
  });
}
