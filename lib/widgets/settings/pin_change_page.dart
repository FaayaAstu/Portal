import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PinChangePage extends StatefulWidget {
  const PinChangePage({super.key});

  @override
  State<PinChangePage> createState() => _PinChangePageState();
}

class _PinChangePageState extends State<PinChangePage> {
  final _controller = TextEditingController();
  final _fieldFocus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fieldFocus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _controller.text;
    if (v.length < 4 || v.length > 8 || int.tryParse(v) == null) {
      setState(() => _error = 'PIN must be 4-8 digits');
      return;
    }
    await context.read<SettingsService>().setKioskPin(v);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Change Kiosk PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Used to unlock the launcher when kiosk mode is on.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _fieldFocus,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '4 – 8 digits',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                onSubmitted: (_) => _save(),
              ),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(_error!, style: const TextStyle(color: Colors.redAccent))
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FocusableActionButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FocusableActionButton(
                      label: 'Save',
                      primary: true,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared TV-friendly button used across the settings pages that need D-pad
/// navigation. Extracted from BrandNamePage so callers can reuse it.
class FocusableActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;
  final bool autofocus;

  const FocusableActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
    this.autofocus = false,
  });

  @override
  State<FocusableActionButton> createState() => _FocusableActionButtonState();
}

class _FocusableActionButtonState extends State<FocusableActionButton> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _focused;
    final bg = active
        ? Colors.white
        : (widget.primary
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05));
    final fg = active ? Colors.black : Colors.white;
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? Colors.white : Colors.white24, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
