import 'dart:math';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:taftaf/core/constants/api_keys.dart';

class ZegoCallService {
  bool _initialized = false;
  String? _currentRoomId;

  Future<void> init() async {
    if (ApiKeys.zegoAppId == 0) {
      throw Exception(
        'ZegoCloud App ID not configured.\n'
        'Visit console.zegocloud.com → create a project → '
        'paste the AppID (int) and AppSign (String) into '
        'lib/core/constants/api_keys.dart.',
      );
    }
    if (_initialized) return;
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        ApiKeys.zegoAppId,
        ZegoScenario.StandardVoiceCall,
        appSign: ApiKeys.zegoAppSign,
      ),
    );
    _initialized = true;
  }

  Future<void> join(
    String channelId,
    String userId,
    String userName, {
    void Function()? onConnected,
    void Function()? onRemoteJoined,
    void Function()? onRemoteLeft,
  }) async {
    _currentRoomId = channelId;
    final streamId = _streamId(userId);

    ZegoExpressEngine.onRoomStateUpdate = (_, state, _, _) {
      if (state == ZegoRoomState.Connected) onConnected?.call();
    };

    ZegoExpressEngine.onRoomUserUpdate = (_, updateType, _) {
      if (updateType == ZegoUpdateType.Add) {
        onRemoteJoined?.call();
      } else {
        onRemoteLeft?.call();
      }
    };

    ZegoExpressEngine.onRoomStreamUpdate = (_, updateType, streamList, _) {
      for (final s in streamList) {
        if (updateType == ZegoUpdateType.Add) {
          ZegoExpressEngine.instance.startPlayingStream(s.streamID);
        } else {
          ZegoExpressEngine.instance.stopPlayingStream(s.streamID);
        }
      }
    };

    await ZegoExpressEngine.instance.loginRoom(
      channelId,
      ZegoUser(userId, userName),
      config: ZegoRoomConfig(0, true, ''),
    );
    await ZegoExpressEngine.instance.startPublishingStream(streamId);
  }

  Future<void> leave() async {
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      if (_currentRoomId != null) {
        await ZegoExpressEngine.instance.logoutRoom(_currentRoomId);
      }
    } catch (_) {}
    _currentRoomId = null;
  }

  Future<void> setMuted(bool muted) async {
    if (!_initialized) return;
    await ZegoExpressEngine.instance.muteMicrophone(muted);
  }

  Future<void> setSpeaker(bool enabled) async {
    if (!_initialized) return;
    await ZegoExpressEngine.instance.setAudioRouteToSpeaker(enabled);
  }

  Future<void> dispose() async {
    await leave();
    try {
      if (_initialized) {
        await ZegoExpressEngine.destroyEngine();
        _initialized = false;
      }
    } catch (_) {}
  }

  static String _streamId(String userId) {
    final clean = userId.replaceAll('-', '');
    return clean.substring(0, min(20, clean.length));
  }
}
