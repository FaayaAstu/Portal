// Dart decoder for the Faayaverse RemoteEvent wire format. Only the discriminator
// strings Portal acts on are modeled explicitly; everything else lands as RawEvent
// and is ignored by the dispatcher.
sealed class RemoteEvent {
  const RemoteEvent();

  static RemoteEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'DPad':
        return DPadEvent(_parseDirection(json['direction'] as String?));
      case 'Select':
        return const SelectEvent();
      case 'Back':
        return const BackEvent();
      case 'Home':
        return const HomeEvent();
      case 'Menu':
        return const MenuEvent();
      case 'PlayPause':
        return const PlayPauseEvent();
      case 'VolumeUp':
        return const VolumeUpEvent();
      case 'VolumeDown':
        return const VolumeDownEvent();
      case 'Mute':
        return const MuteEvent();
      case 'ChannelUp':
        return const ChannelUpEvent();
      case 'ChannelDown':
        return const ChannelDownEvent();
      case 'Power':
        return const PowerEvent();
      case 'Search':
        return const SearchEvent();
      case 'Info':
        return const InfoEvent();
      case 'Voice':
        return const VoiceEvent();
      case 'Keyboard':
        return KeyboardEvent(
          keyCode: json['keyCode'] as int? ?? 0,
          keyChar: (json['keyChar'] as String?)?.isNotEmpty == true
              ? (json['keyChar'] as String)
              : null,
        );
      case 'ctx.navigate':
        return NavigateEvent(
          screen: json['screen'] as String? ?? '',
          params: (json['params'] as Map?)?.cast<String, String>() ?? const {},
        );
      default:
        return RawEvent(type ?? 'unknown', json);
    }
  }
}

enum RemoteDirection { up, down, left, right }

RemoteDirection _parseDirection(String? s) {
  switch (s) {
    case 'UP':
      return RemoteDirection.up;
    case 'DOWN':
      return RemoteDirection.down;
    case 'LEFT':
      return RemoteDirection.left;
    case 'RIGHT':
      return RemoteDirection.right;
    default:
      return RemoteDirection.up;
  }
}

class DPadEvent extends RemoteEvent {
  final RemoteDirection direction;
  const DPadEvent(this.direction);
}

class SelectEvent extends RemoteEvent { const SelectEvent(); }
class BackEvent extends RemoteEvent { const BackEvent(); }
class HomeEvent extends RemoteEvent { const HomeEvent(); }
class MenuEvent extends RemoteEvent { const MenuEvent(); }
class PlayPauseEvent extends RemoteEvent { const PlayPauseEvent(); }
class VolumeUpEvent extends RemoteEvent { const VolumeUpEvent(); }
class VolumeDownEvent extends RemoteEvent { const VolumeDownEvent(); }
class MuteEvent extends RemoteEvent { const MuteEvent(); }
class ChannelUpEvent extends RemoteEvent { const ChannelUpEvent(); }
class ChannelDownEvent extends RemoteEvent { const ChannelDownEvent(); }
class PowerEvent extends RemoteEvent { const PowerEvent(); }
class SearchEvent extends RemoteEvent { const SearchEvent(); }
class InfoEvent extends RemoteEvent { const InfoEvent(); }
class VoiceEvent extends RemoteEvent { const VoiceEvent(); }

class KeyboardEvent extends RemoteEvent {
  final int keyCode;
  final String? keyChar;
  const KeyboardEvent({required this.keyCode, this.keyChar});
}

class NavigateEvent extends RemoteEvent {
  final String screen;
  final Map<String, String> params;
  const NavigateEvent({required this.screen, this.params = const {}});
}

class RawEvent extends RemoteEvent {
  final String type;
  final Map<String, dynamic> raw;
  const RawEvent(this.type, this.raw);
}
