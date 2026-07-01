import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:taftaf/core/models/call_model.dart';
import 'package:taftaf/core/services/zego_call_service.dart';

enum CallStatus { idle, calling, ringing, connecting, active, ended }

class CallState {
  final CallModel? call;
  final CallStatus status;
  final bool isMuted;
  final bool isSpeakerOn;
  final int durationSeconds;
  final String? errorMessage;

  const CallState({
    this.call,
    this.status = CallStatus.idle,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.durationSeconds = 0,
    this.errorMessage,
  });

  CallState copyWith({
    CallModel? call,
    CallStatus? status,
    bool? isMuted,
    bool? isSpeakerOn,
    int? durationSeconds,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CallState(
        call: call ?? this.call,
        status: status ?? this.status,
        isMuted: isMuted ?? this.isMuted,
        isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class CallNotifier extends StateNotifier<CallState> {
  CallNotifier() : super(const CallState());

  final _zego = ZegoCallService();
  Timer? _durationTimer;

  static const _inviteKey = 'taftaf_call_invite_';

  // ── Caller side ───────────────────────────────────────────────────────────

  Future<void> startCall({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
  }) async {
    final channelId = CallModel.deriveChannel(callerId, calleeId);
    final call = CallModel(
      id: const Uuid().v4(),
      callerId: callerId,
      callerName: callerName,
      calleeId: calleeId,
      calleeName: calleeName,
      channelId: channelId,
      initiatedAt: DateTime.now(),
    );

    state = CallState(call: call, status: CallStatus.calling);
    await _persistInvite(call);

    try {
      await _zego.init();
      await _zego.join(
        channelId,
        callerId,
        callerName,
        onRemoteJoined: () {
          if (mounted && state.status == CallStatus.calling) {
            state = state.copyWith(
              status: CallStatus.active,
              durationSeconds: 0,
              clearError: true,
            );
            _startTimer();
          }
        },
        onRemoteLeft: () {
          if (mounted) endCall();
        },
      );
    } catch (e) {
      if (!mounted) return;
      await _removeInvite(calleeId);
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: e.toString(),
      );
      await _resetAfterDelay();
    }
  }

  // ── Callee side ───────────────────────────────────────────────────────────

  /// Called by the root polling loop when an incoming call is detected.
  void notifyIncoming(CallModel call) {
    if (state.status != CallStatus.idle) return;
    state = CallState(call: call, status: CallStatus.ringing);
  }

  Future<void> acceptCall() async {
    final call = state.call;
    if (call == null) return;

    state = state.copyWith(status: CallStatus.connecting, clearError: true);
    await _removeInvite(call.calleeId);

    try {
      await _zego.init();
      await _zego.join(
        call.channelId,
        call.calleeId,
        call.calleeName,
        onConnected: () {
          if (mounted) {
            state = state.copyWith(
              status: CallStatus.active,
              durationSeconds: 0,
              clearError: true,
            );
            _startTimer();
          }
        },
        onRemoteLeft: () {
          if (mounted) endCall();
        },
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: e.toString(),
      );
      await _resetAfterDelay();
    }
  }

  Future<void> declineCall() async {
    if (state.call != null) await _removeInvite(state.call!.calleeId);
    state = const CallState();
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Future<void> endCall() async {
    _durationTimer?.cancel();
    final prev = state;
    state = state.copyWith(status: CallStatus.ended);
    await _zego.leave();
    if (prev.call != null) await _removeInvite(prev.call!.calleeId);
    await _resetAfterDelay();
  }

  Future<void> toggleMute() async {
    final muted = !state.isMuted;
    await _zego.setMuted(muted);
    if (mounted) state = state.copyWith(isMuted: muted);
  }

  Future<void> toggleSpeaker() async {
    final on = !state.isSpeakerOn;
    await _zego.setSpeaker(on);
    if (mounted) state = state.copyWith(isSpeakerOn: on);
  }

  Future<void> _resetAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await _zego.dispose();
      state = const CallState();
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      }
    });
  }

  // ── SharedPreferences signaling ───────────────────────────────────────────
  // Enables same-device call delivery: the caller writes an invite, the
  // owner's app polls for it and triggers the incoming-call overlay.
  // For multi-device production use, replace this with a cloud signal
  // (Firebase Realtime DB, Supabase Realtime, ZegoCloud ZIM, etc.).

  static Future<void> _persistInvite(CallModel call) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_inviteKey${call.calleeId}',
      jsonEncode(call.toJson()),
    );
  }

  static Future<void> _removeInvite(String calleeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_inviteKey$calleeId');
  }

  /// Checks SharedPreferences for a pending call invite for [userId].
  /// Returns null if no valid (≤ 60 s old) invite exists.
  static Future<CallModel?> pollForIncoming(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_inviteKey$userId');
    if (raw == null) return null;
    try {
      final call = CallModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(call.initiatedAt).inSeconds > 60) {
        await prefs.remove('$_inviteKey$userId');
        return null;
      }
      return call;
    } catch (_) {
      await prefs.remove('$_inviteKey$userId');
      return null;
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _zego.dispose();
    super.dispose();
  }
}

final callProvider =
    StateNotifierProvider<CallNotifier, CallState>((_) => CallNotifier());
