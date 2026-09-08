import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';
import '../../../routes/app_router.dart';

class EventCardWidget extends StatefulWidget {
  final String _title;
  final String _description;
  final String _location;
  final DateTime _date;
  final void Function() _editButton;
  final void Function() _deleteButton;
  final void Function() _downloadButton;

  const EventCardWidget({
    super.key,
    required this._title,
    required this._description,
    required this._location,
    required this._date,
    required this._editButton,
    required this._deleteButton,
    required this._downloadButton,
  });

  @override
  State<EventCardWidget> createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends State<EventCardWidget> {
  bool showOptionButton = false;
  double optionButtonWidth = 0.0;
  static const double maxOptionButtonWidth = 48.0;

  @override
  void initState() {
    super.initState();

    AppRouter.router.routerDelegate.addListener(() {
      final String currentRoute = AppRouter.router.routerDelegate.currentConfiguration.last.matchedLocation;
      if (currentRoute != AppRoutes.eventRoute.path) {
        setState(() {
          showOptionButton = false;
          optionButtonWidth = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final delta = details.delta.dx;

          if (delta < 0) {
            optionButtonWidth = (optionButtonWidth + (-delta)).clamp(0, maxOptionButtonWidth);
          } else if (delta > 0) {
            optionButtonWidth = (optionButtonWidth - delta).clamp(0, maxOptionButtonWidth);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          optionButtonWidth = optionButtonWidth > (maxOptionButtonWidth / 2)
              ? maxOptionButtonWidth
              : 0;
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
                        const Icon(Icons.event, size: 40.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget._title, style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(widget._date),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              Text(
                                widget._location,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(thickness: 1.5),
                              const SizedBox(height: 8.0),
                              Text(
                                widget._description,
                                textAlign: TextAlign.justify,
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
                  width: optionButtonWidth,
                  color: Colors.transparent,
                  child: optionButtonWidth > 0
                      ? Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: InkWell(
                                  onTap: widget._editButton,
                                  child: Container(
                                    color: Colors.orange,
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
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: widget._deleteButton,
                                  child: Container(
                                    color: Colors.red,
                                    child: const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSizes.p8),
                                        child: FaIcon(
                                          FontAwesomeIcons.trash,
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: widget._downloadButton,
                                  child: Container(
                                    color: Colors.blue,
                                    child: const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSizes.p8),
                                        child: FaIcon(
                                          FontAwesomeIcons.download,
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
