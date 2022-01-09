import 'package:flutter/widgets.dart';

class FAProgressBar extends StatefulWidget {
  FAProgressBar({
    Key? key,
    this.currentValue = 0,
    this.maxValue = 100,
    this.size = 30,
    this.animatedDuration = const Duration(milliseconds: 300),
    this.direction = Axis.horizontal,
    this.verticalDirection = VerticalDirection.down,
    BorderRadiusGeometry? borderRadius,
    this.border,
    this.backgroundColor = const Color(0x00FFFFFF),
    this.progressColor = const Color(0xFFFA7268),
    this.changeColorValue,
    this.changeProgressColor = const Color(0xFF5F4B8B),
    this.displayText,
    this.displayTextStyle =
        const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
  })  : _borderRadius = borderRadius ?? BorderRadius.circular(8),
        super(key: key);
  final int currentValue;
  final int maxValue;
  final double size;
  final Duration animatedDuration;
  final Axis direction;
  final VerticalDirection verticalDirection;
  final BorderRadiusGeometry _borderRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  final Color progressColor;
  final int? changeColorValue;
  final Color changeProgressColor;
  final String? displayText;
  final TextStyle displayTextStyle;

  @override
  _FAProgressBarState createState() => _FAProgressBarState();
}

class _FAProgressBarState extends State<FAProgressBar>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;
  double _currentBegin = 0;
  double _currentEnd = 0;

  @override
  void initState() {
    _controller =
        AnimationController(duration: widget.animatedDuration, vsync: this);
    _animation = Tween<double>(begin: _currentBegin, end: _currentEnd)
        .animate(_controller);
    triggerAnimation();
    super.initState();
  }

  @override
  void didUpdateWidget(FAProgressBar old) {
    triggerAnimation();
    super.didUpdateWidget(old);
  }

  void triggerAnimation() {
    setState(() {
      _currentBegin = _animation.value;

      if (widget.currentValue == 0 || widget.maxValue == 0) {
        _currentEnd = 0;
      } else {
        _currentEnd = widget.currentValue / widget.maxValue;
      }

      _animation = Tween<double>(begin: _currentBegin, end: _currentEnd)
          .animate(_controller);
    });
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) => AnimatedProgressBar(
        animation: _animation,
        widget: widget,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  const AnimatedProgressBar({
    Key? key,
    required Animation<double> animation,
    required this.widget,
  }) : super(key: key, listenable: animation);

  final FAProgressBar widget;

  double transformValue(x, begin, end, before) {
    double y = (end * x - (begin - before)) * (1 / before);
    return y < 0 ? 0 : ((y > 1) ? 1 : y);
  }

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    Color progressColor = widget.progressColor;

    if (widget.changeColorValue != null) {
      final _colorTween = ColorTween(
        begin: widget.progressColor,
        end: widget.changeProgressColor,
      );

      progressColor = _colorTween.transform(transformValue(
        animation.value,
        widget.changeColorValue,
        widget.maxValue,
        5,
      ))!;
    }

    Widget progressWidget = Container(
      decoration: BoxDecoration(
        color: progressColor,
        borderRadius: widget._borderRadius,
        border: widget.border,
      ),
    );

    Widget? textProgress;

    if (widget.displayText != null) {
      textProgress = Container(
        alignment: widget.direction == Axis.horizontal
            ? const FractionalOffset(0.04, 0.5)
            : (widget.verticalDirection == VerticalDirection.up
                ? const FractionalOffset(0.5, 0.96)
                : const FractionalOffset(0.5, 0.04)),
        child: Text(
          (animation.value * widget.maxValue).toInt().toString() +
              widget.displayText!,
          softWrap: false,
          style: widget.displayTextStyle,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: widget.direction == Axis.vertical ? widget.size : null,
        height: widget.direction == Axis.horizontal ? widget.size : null,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget._borderRadius,
          border: widget.border,
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Flex(
              direction: widget.direction,
              verticalDirection: widget.verticalDirection,
              children: <Widget>[
                Expanded(
                    flex: (animation.value * 100).toInt(),
                    child: progressWidget),
                Expanded(
                  flex: 100 - (animation.value * 100).toInt(),
                  child: Container(),
                )
              ],
            ),
            textProgress ?? Container(),
          ],
        ),
      ),
    );
  }
}
