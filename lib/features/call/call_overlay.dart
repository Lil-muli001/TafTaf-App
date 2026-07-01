import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/providers/call_provider.dart';
import 'package:taftaf/core/providers/providers.dart';

/// Root-level overlay that covers the entire screen during any call state.
/// Placed inside the MaterialApp builder Stack — appears above all routes.
class CallOverlay extends ConsumerWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(callProvider.select((s) => s.status));
    if (status == CallStatus.idle) return const SizedBox.shrink();
    return const _CallOverlayContent();
  }
}

// ── Stateful host (holds animation controllers + dot timer) ──────────────────

class _CallOverlayContent extends ConsumerStatefulWidget {
  const _CallOverlayContent();

  @override
  ConsumerState<_CallOverlayContent> createState() =>
      _CallOverlayContentState();
}

class _CallOverlayContentState extends ConsumerState<_CallOverlayContent>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Opacity;

  int _dotCount = 1;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _ring1 = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(
        parent: _pulseCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ring2 = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(
        parent: _pulseCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(callProvider);
    final notifier = ref.read(callProvider.notifier);
    final user = ref.read(authProvider).currentUser;

    final call = cs.call;
    final remoteName = call == null
        ? ''
        : (user?.id == call.callerId ? call.calleeName : call.callerName);

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(cs.status),
            child: switch (cs.status) {
              CallStatus.calling => _OutgoingView(
                  calleeName: call?.calleeName ?? '',
                  dots: '.' * _dotCount,
                  ring1: _ring1,
                  ring2: _ring2,
                  ring1Opacity: _ring1Opacity,
                  ring2Opacity: _ring2Opacity,
                  pulseCtrl: _pulseCtrl,
                  accentColor: AppColors.primary,
                  onCancel: () => notifier.endCall(),
                ),
              CallStatus.ringing => _IncomingView(
                  callerName: call?.callerName ?? '',
                  ring1: _ring1,
                  ring2: _ring2,
                  ring1Opacity: _ring1Opacity,
                  ring2Opacity: _ring2Opacity,
                  pulseCtrl: _pulseCtrl,
                  onAccept: () => notifier.acceptCall(),
                  onDecline: () => notifier.declineCall(),
                ),
              CallStatus.connecting => const _ConnectingView(),
              CallStatus.active => _ActiveView(
                  remoteName: remoteName,
                  duration: _formatDuration(cs.durationSeconds),
                  isMuted: cs.isMuted,
                  isSpeakerOn: cs.isSpeakerOn,
                  onMute: () => notifier.toggleMute(),
                  onSpeaker: () => notifier.toggleSpeaker(),
                  onEnd: () => notifier.endCall(),
                ),
              CallStatus.ended => _EndedView(
                  duration: _formatDuration(cs.durationSeconds),
                  error: cs.errorMessage,
                ),
              CallStatus.idle => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

// ── Outgoing call (caller waiting for answer) ─────────────────────────────────

class _OutgoingView extends StatelessWidget {
  final String calleeName;
  final String dots;
  final Animation<double> ring1;
  final Animation<double> ring2;
  final Animation<double> ring1Opacity;
  final Animation<double> ring2Opacity;
  final AnimationController pulseCtrl;
  final Color accentColor;
  final VoidCallback onCancel;

  const _OutgoingView({
    required this.calleeName,
    required this.dots,
    required this.ring1,
    required this.ring2,
    required this.ring1Opacity,
    required this.ring2Opacity,
    required this.pulseCtrl,
    required this.accentColor,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          'TafTaf Voice Call',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        _PulsingAvatar(
          label: calleeName.isNotEmpty ? calleeName[0].toUpperCase() : '?',
          avatarColor: AppColors.primarySurface,
          borderColor: accentColor,
          textColor: accentColor,
          ring1: ring1,
          ring2: ring2,
          ring1Opacity: ring1Opacity,
          ring2Opacity: ring2Opacity,
          ringColor: accentColor,
          pulseCtrl: pulseCtrl,
        ),
        const SizedBox(height: 30),
        Text(
          calleeName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Calling$dots',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        _RoundButton(
          icon: Icons.call_end_rounded,
          color: const Color(0xFFFF3B30),
          size: 72,
          onTap: onCancel,
        ),
        const SizedBox(height: 52),
      ],
    );
  }
}

// ── Incoming call (callee receiving call) ─────────────────────────────────────

class _IncomingView extends StatelessWidget {
  final String callerName;
  final Animation<double> ring1;
  final Animation<double> ring2;
  final Animation<double> ring1Opacity;
  final Animation<double> ring2Opacity;
  final AnimationController pulseCtrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingView({
    required this.callerName,
    required this.ring1,
    required this.ring2,
    required this.ring1Opacity,
    required this.ring2Opacity,
    required this.pulseCtrl,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'Incoming Voice Call',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        _PulsingAvatar(
          label: callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
          avatarColor: AppColors.success.withValues(alpha: 0.15),
          borderColor: AppColors.success,
          textColor: AppColors.success,
          ring1: ring1,
          ring2: ring2,
          ring1Opacity: ring1Opacity,
          ring2Opacity: ring2Opacity,
          ringColor: AppColors.success,
          pulseCtrl: pulseCtrl,
        ),
        const SizedBox(height: 30),
        Text(
          callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'TafTaf · Property Inquiry',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LabeledButton(
              icon: Icons.call_end_rounded,
              color: const Color(0xFFFF3B30),
              label: 'Decline',
              onTap: onDecline,
            ),
            _LabeledButton(
              icon: Icons.call_rounded,
              color: AppColors.success,
              label: 'Accept',
              onTap: onAccept,
            ),
          ],
        ),
        const SizedBox(height: 52),
      ],
    );
  }
}

// ── Connecting ────────────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          SizedBox(height: 20),
          Text(
            'Connecting...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Active call ───────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final String remoteName;
  final String duration;
  final bool isMuted;
  final bool isSpeakerOn;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;

  const _ActiveView({
    required this.remoteName,
    required this.duration,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.onMute,
    required this.onSpeaker,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Connected',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Static avatar with green border
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface,
            border: Border.all(color: AppColors.success, width: 2.5),
          ),
          alignment: Alignment.center,
          child: Text(
            remoteName.isNotEmpty ? remoteName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          remoteName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          duration,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? 'Unmute' : 'Mute',
              active: isMuted,
              activeColor: AppColors.primary,
              activeIconColor: AppColors.black,
              onTap: onMute,
            ),
            _RoundButton(
              icon: Icons.call_end_rounded,
              color: const Color(0xFFFF3B30),
              size: 72,
              onTap: onEnd,
            ),
            _ControlButton(
              icon: isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              label: isSpeakerOn ? 'Speaker' : 'Earpiece',
              active: isSpeakerOn,
              activeColor: AppColors.primary,
              activeIconColor: AppColors.black,
              onTap: onSpeaker,
            ),
          ],
        ),
        const SizedBox(height: 52),
      ],
    );
  }
}

// ── Call ended ────────────────────────────────────────────────────────────────

class _EndedView extends StatelessWidget {
  final String duration;
  final String? error;

  const _EndedView({required this.duration, this.error});

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              hasError ? Icons.error_outline_rounded : Icons.call_end_rounded,
              color: hasError ? AppColors.error : Colors.white70,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            hasError ? 'Call Failed' : 'Call Ended',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else if (duration != '00:00')
            Text(
              duration,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared building blocks ────────────────────────────────────────────────────

class _PulsingAvatar extends StatelessWidget {
  final String label;
  final Color avatarColor;
  final Color borderColor;
  final Color textColor;
  final Color ringColor;
  final Animation<double> ring1;
  final Animation<double> ring2;
  final Animation<double> ring1Opacity;
  final Animation<double> ring2Opacity;
  final AnimationController pulseCtrl;

  const _PulsingAvatar({
    required this.label,
    required this.avatarColor,
    required this.borderColor,
    required this.textColor,
    required this.ringColor,
    required this.ring1,
    required this.ring2,
    required this.ring1Opacity,
    required this.ring2Opacity,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        return SizedBox(
          width: 210,
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Opacity(
                opacity: ring2Opacity.value,
                child: Transform.scale(
                  scale: ring2.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
              // Inner ring
              Opacity(
                opacity: ring1Opacity.value,
                child: Transform.scale(
                  scale: ring1.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarColor,
          border: Border.all(color: borderColor, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.44),
      ),
    );
  }
}

class _LabeledButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _LabeledButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(icon: icon, color: color, size: 68, onTap: onTap),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color activeIconColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeIconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : Colors.white12,
            ),
            child: Icon(
              icon,
              color: active ? activeIconColor : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
