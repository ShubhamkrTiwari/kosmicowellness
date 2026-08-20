import 'dart:async';
import 'package:flutter/material.dart';

class BannerItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String buttonText;
  final bool isAsset;

  BannerItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.buttonText,
    this.isAsset = false,
  });
}

class BannerCarousel extends StatefulWidget {
  final VoidCallback? onTap;
  const BannerCarousel({super.key, this.onTap});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<BannerItem> _banners = [
    BannerItem(
      title: '', // Empty because image already has text
      subtitle: '',
      imageUrl: 'assets/images/adbannersweetmonk.png',
      buttonText: 'Buy Now',
      isAsset: true,
    ),
    BannerItem(
      title: '', // Image likely has its own text
      subtitle: '',
      imageUrl: 'assets/images/scanplatebanner.png',
      buttonText: 'Scan Now',
      isAsset: true,
    ),
    BannerItem(
      title: '', 
      subtitle: '',
      imageUrl: 'assets/images/socialbanner.png',
      buttonText: 'Join Now',
      isAsset: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 180, 
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerCard(_banners[index], colorScheme);
            },
          ),
        ),
        Positioned(
          bottom: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => _buildIndicator(index == _currentPage, colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(bool isActive, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          )
        ],
      ),
    );
  }

  Widget _buildBannerCard(BannerItem banner, ColorScheme colorScheme) {
    final bool hasText = banner.title.isNotEmpty || banner.subtitle.isNotEmpty;
    
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16), // Re-added margin for visible rounded corners
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24), // Added corner radius
          image: DecorationImage(
            image: banner.isAsset 
                ? AssetImage(banner.imageUrl) as ImageProvider
                : NetworkImage(banner.imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24), // Ensure content/image is clipped to rounded corners
          child: Stack(
            children: [
            if (hasText) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.title.isNotEmpty)
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    if (banner.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        banner.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(banner.buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
