import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/router/app_router.dart';

// ── Page data ─────────────────────────────────────────────────────────────────

class _PageData {
  final String imageUrl;
  final String number;
  final String title;
  final String body;
  final String quote;

  const _PageData({
    required this.imageUrl,
    required this.number,
    required this.title,
    required this.body,
    required this.quote,
  });
}

const List<_PageData> _kPages = [
  _PageData(
    // Portrait-optimised: 900×1400 @ q=82 → ~3× smaller download than 1920×1080@95
    imageUrl:
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c'
        '?w=900&h=1400&q=82&fit=crop&auto=format',
    number: '01',
    title: 'Find Your\nPerfect Home',
    body:
        'Discover spaces that speak to your soul — from cozy apartments '
        'to grand estates. Your dream home is closer than you think.',
    quote: '"Home is not a place.\nIt\'s a feeling."',
  ),
  _PageData(
    imageUrl:
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6'
        '?w=900&h=1400&q=82&fit=crop&auto=format',
    number: '02',
    title: 'Every House\nTells a Story',
    body:
        'Browse verified listings handpicked for quality, safety, and '
        'style. At TafTaf, every property meets our premium standard.',
    quote: '"The magic of home —\nit always feels great to come back."',
  ),
  _PageData(
    imageUrl:
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef'
        '?w=900&h=1400&q=82&fit=crop&auto=format',
    number: '03',
    title: 'Invest in\nYour Future',
    body:
        'From prime plots to high-yield Airbnbs, grow your wealth with '
        'the smartest real estate choices in Kenya.',
    quote: '"Land is the one thing they\naren\'t making more of."  — Mark Twain',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taftaf_onboarding_done', true);
    if (mounted) context.go(AppRoutes.signup);
  }

  void _advance() {
    if (_page < _kPages.length - 1) {
      _ctrl.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background image PageView (swipeable) ──────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _kPages.length,
            itemBuilder: (_, i) => _BgImage(url: _kPages[i].imageUrl),
          ),

          // ── Cinematic gradient: light veil top + deep shadow bottom ─────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000), // soft top shadow
                      Color(0x00000000), // clear mid
                      Color(0xBB000000), // strong lower mid
                      Color(0xF2000000), // near-black bottom
                    ],
                    stops: [0.0, 0.20, 0.52, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Neon-lime left accent strip (brand signature) ───────────────
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha: 0.70),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Skip button ─────────────────────────────────────────────────
          if (_page < _kPages.length - 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, right: 20),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      shape: const StadiumBorder(
                        side: BorderSide(color: Color(0x40FFFFFF)),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
            ),

          // ── Animated content panel (key → re-animates on page change) ───
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _ContentPanel(
              key: ValueKey(_page),
              data: _kPages[_page],
              ctrl: _ctrl,
              page: _page,
              total: _kPages.length,
              onAdvance: _advance,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background image ──────────────────────────────────────────────────────────

class _BgImage extends StatelessWidget {
  final String url;
  const _BgImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 600),
      placeholder: (_, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C111F), Color(0xFF0F1E10)],
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C111F), Color(0xFF0F1E10)],
          ),
        ),
      ),
    );
  }
}

// ── Content panel ─────────────────────────────────────────────────────────────

class _ContentPanel extends StatelessWidget {
  final _PageData data;
  final PageController ctrl;
  final int page;
  final int total;
  final VoidCallback onAdvance;

  const _ContentPanel({
    super.key,
    required this.data,
    required this.ctrl,
    required this.page,
    required this.total,
    required this.onAdvance,
  });

  bool get _isLast => page == total - 1;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, bottom + 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Page number badge ────────────────────────────────────────────
          _PageBadge(number: data.number)
              .animate()
              .fadeIn(duration: 400.ms, delay: 60.ms)
              .slideY(begin: 0.5, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 20),

          // ── Main title ───────────────────────────────────────────────────
          Text(
            data.title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 550.ms, delay: 160.ms)
              .slideY(begin: 0.35, end: 0, duration: 550.ms, curve: Curves.easeOutCubic)
              .then(delay: 80.ms)
              .shimmer(
                duration: 1600.ms,
                color: Colors.white.withValues(alpha: 0.20),
              ),

          const SizedBox(height: 16),

          // ── Body ─────────────────────────────────────────────────────────
          Text(
            data.body,
            style: const TextStyle(
              color: Color(0xBBFFFFFF),
              fontFamily: 'Poppins',
              fontSize: 14.5,
              height: 1.72,
              fontWeight: FontWeight.w400,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 280.ms)
              .slideY(begin: 0.25, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          // ── Quote block ──────────────────────────────────────────────────
          _QuoteBlock(quote: data.quote)
              .animate()
              .fadeIn(duration: 500.ms, delay: 420.ms)
              .slideX(begin: -0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 36),

          // ── Dots + CTA row ────────────────────────────────────────────────
          Row(
            children: [
              SmoothPageIndicator(
                controller: ctrl,
                count: total,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: AppColors.primary,
                  dotColor: Colors.white.withValues(alpha: 0.28),
                  expansionFactor: 3.5,
                  spacing: 6,
                ),
              ),
              const Spacer(),
              _CtaButton(
                label: _isLast ? 'Get Started' : 'Next',
                onTap: onAdvance,
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 560.ms)
                  .slideX(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }
}

// ── Page badge ────────────────────────────────────────────────────────────────

class _PageBadge extends StatelessWidget {
  final String number;
  const _PageBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            number,
            style: const TextStyle(
              color: AppColors.primary,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quote block ───────────────────────────────────────────────────────────────

class _QuoteBlock extends StatelessWidget {
  final String quote;
  const _QuoteBlock({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 54,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            quote,
            style: GoogleFonts.lora(
              color: AppColors.primary.withValues(alpha: 0.90),
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.65,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.black,
              size: 17,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.03,
            duration: 1800.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
