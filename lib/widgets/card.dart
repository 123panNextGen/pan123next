import 'package:fluent_ui/fluent_ui.dart';

class RounderCard extends StatefulWidget {
  const RounderCard({
    super.key,
    required this.child,
    this.margin,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding = const EdgeInsetsDirectional.all(12);
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<RounderCard> createState() => _RounderCardState();
}

class _RounderCardState extends State<RounderCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      borderRadius: BorderRadius.circular(8),
      margin: widget.margin,
      backgroundColor: widget.backgroundColor,
      borderColor: widget.borderColor,
      child: widget.child,
    );
  }
}
