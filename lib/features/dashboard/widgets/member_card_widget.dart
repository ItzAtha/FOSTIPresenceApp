import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';
import '../../../shared/models/member_model.dart';

class MemberCardWidget extends StatefulWidget {
  final String _name;
  final String _nim;
  final Divisions _division;
  final void Function() _editButton;

  const MemberCardWidget({
    super.key,
    required this._name,
    required this._nim,
    required this._division,
    required this._editButton,
  });

  @override
  State<MemberCardWidget> createState() => _MemberCardWidgetState();
}

class _MemberCardWidgetState extends State<MemberCardWidget> {
  bool showEditButton = false;
  double editButtonWidth = 0.0;
  static const double maxEditButtonWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final delta = details.delta.dx;

          if (delta < 0) {
            editButtonWidth = (editButtonWidth + (-delta)).clamp(0, maxEditButtonWidth);
          } else if (delta > 0) {
            editButtonWidth = (editButtonWidth - delta).clamp(0, maxEditButtonWidth);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          editButtonWidth = editButtonWidth > (maxEditButtonWidth / 2) ? maxEditButtonWidth : 0;
        });
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    child: Row(
                      children: <Widget>[
                        const FaIcon(FontAwesomeIcons.solidUser, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget._name, style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                'NIM: ${widget._nim}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                'Division: ${widget._division.name}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                'Generation: ${widget._nim.substring(4, 6)}/${((int.tryParse(widget._nim.substring(4, 6)) ?? 0) + 1).toString()}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: editButtonWidth,
                  color: Colors.orange,
                  child: editButtonWidth > 0
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget._editButton,
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSizes.p8),
                                child: FaIcon(
                                  FontAwesomeIcons.pen,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
