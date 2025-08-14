import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TapToCopy extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? feedbackMessage;

  const TapToCopy({
    Key? key,
    required this.text,
    this.style,
    this.feedbackMessage,
  }) : super(key: key);

  Future<void> _copyText(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      // Optional verification
      final copied = await Clipboard.getData('text/plain');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyText(context),
      child: Text(text),
    );
  }
}

class BlinkTapToCopy extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final String? feedbackMessage;

  const BlinkTapToCopy({
    Key? key,
    required this.text,
    this.style,
    this.feedbackMessage,
  }) : super(key: key);

  @override
  State<BlinkTapToCopy> createState() => _BlinkTapToCopyState();
}

class _BlinkTapToCopyState extends State<BlinkTapToCopy>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;

  Future<void> _copyText() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));

      // Trigger blink animation
      for (int i = 0; i < 2; i++) {
        setState(() => _opacity = 0.0);
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _opacity = 1.0);
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Optional feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.feedbackMessage ?? 'Copied to clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copyText,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 150),
        child: Text(
          widget.text,
          style:
              widget.style ?? const TextStyle(fontSize: 16, color: Colors.blue),
        ),
      ),
    );
  }
}

class AnimatedTapToCopy extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final String? feedbackMessage;

  const AnimatedTapToCopy({
    Key? key,
    required this.text,
    this.style,
    this.feedbackMessage,
  }) : super(key: key);

  @override
  State<AnimatedTapToCopy> createState() => _AnimatedTapToCopyState();
}

class _AnimatedTapToCopyState extends State<AnimatedTapToCopy> {
  bool _copied = false;

  Future<void> _copyText() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
      setState(() => _copied = true);

      // Auto-revert after short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _copied = false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.feedbackMessage ?? 'Copied to clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copyText,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: _copied
            ? const Icon(Icons.check,
                color: Colors.green, key: ValueKey('check'))
            : Text(
                widget.text,
                key: const ValueKey('text'),
                style: widget.style ??
                    const TextStyle(fontSize: 16, color: Colors.blue),
              ),
      ),
    );
  }
}

class BlinkBorderTapToCopy extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final String? feedbackMessage;

  const BlinkBorderTapToCopy({
    Key? key,
    required this.text,
    this.style,
    this.feedbackMessage,
  }) : super(key: key);

  @override
  State<BlinkBorderTapToCopy> createState() => _BlinkBorderTapToCopyState();
}

class _BlinkBorderTapToCopyState extends State<BlinkBorderTapToCopy> {
  bool _highlight = false;

  Future<void> _copyText() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));

      // Blink border twice
      for (int i = 0; i < 2; i++) {
        setState(() => _highlight = true);
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _highlight = false);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copyText,
      child: Text(
        widget.text,
      ),
    );
  }
}
