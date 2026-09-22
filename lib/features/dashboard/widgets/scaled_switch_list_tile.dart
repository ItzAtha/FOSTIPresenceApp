import 'package:material_ui/material_ui.dart';

class ScaledSwitchListTile extends StatelessWidget {
  const ScaledSwitchListTile({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onChanged,
    this.scale = 1.0,
  });

  final bool value;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final ValueChanged<bool> onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: () => onChanged(!value),
      trailing: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Switch(
            value: value,
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }
}