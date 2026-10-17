import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';

class FaqExpansionTile extends StatefulWidget {
  const FaqExpansionTile({
    super.key,
    required this._title,
    this._subtitle,
    required this._description,
  });

  final String _title;
  final String? _subtitle;
  final Widget _description;

  @override
  State<FaqExpansionTile> createState() => _FaqExpansionTileState();
}

class _FaqExpansionTileState extends State<FaqExpansionTile> {
  bool isOpened = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget._title.tr(context: context),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: widget._subtitle != null ? Text(widget._subtitle!.tr(context: context)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedRotation(
            turns: isOpened ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 20.0,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
      expansionAnimationStyle: const AnimationStyle(
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 500),
      ),
      onExpansionChanged: (isExpanded) {
        setState(() => isOpened = isExpanded);
      },
      children: <Widget>[
        Padding(padding: const EdgeInsets.all(AppSizes.p8), child: widget._description),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
