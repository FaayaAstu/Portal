import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BrandNamePage extends StatefulWidget {
  const BrandNamePage({super.key});

  @override
  State<BrandNamePage> createState() => _BrandNamePageState();
}

class _BrandNamePageState extends State<BrandNamePage> {
  late final TextEditingController _controller;
  final FocusNode _fieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: context.read<SettingsService>().brandName);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fieldFocus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsService>().setBrandName(_controller.text);
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
        title: const Text('Brand Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Shown on the home screen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _fieldFocus,
                maxLength: 24,
                style: const TextStyle(fontSize: 24, letterSpacing: 2),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'FAAYA',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _FocusableActionButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FocusableActionButton(
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

class _FocusableActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _FocusableActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  State<_FocusableActionButton> createState() => _FocusableActionButtonState();
}

class _FocusableActionButtonState extends State<_FocusableActionButton> {
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
          child: Text(
            widget.label,
            style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
