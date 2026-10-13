import 'package:attendance_management/routes/app_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';

class MemberExcelCardWidget extends StatefulWidget {
  final String _name;
  final Map<String, int> _data;
  final void Function() _viewButton;
  final void Function() _editButton;

  const MemberExcelCardWidget({
    super.key,
    required this._name,
    required this._data,
    required this._viewButton,
    required this._editButton,
  });

  @override
  State<MemberExcelCardWidget> createState() => _MemberExcelCardWidgetState();
}

class _MemberExcelCardWidgetState extends State<MemberExcelCardWidget> {
  bool showEditButton = false;
  double editButtonWidth = 0.0;
  static const double maxEditButtonWidth = 48.0;

  void handleRouteChange() {
    if (!mounted) return;

    final String currentRoute =
        AppRouter.router.routerDelegate.currentConfiguration.last.matchedLocation;

    if (currentRoute != AppRoutes.memberRoute.path) {
      setState(() {
        showEditButton = false;
        editButtonWidth = 0.0;
      });
    }
  }

  Widget getDivisionBadge(MapEntry<String, int> data) {
    String division = data.key.toUpperCase();
    int level = data.value;

    String text;
    MaterialColor color;

    switch (division) {
      case "KEILMUAN DAN RISET TEKNOLOGI" || "RISTEK":
        text = "RISTEK : $level";
        color = Colors.green;
        break;
      case "HUBUNGAN PUBLIK" || "HUBPUB":
        text = "HUBPUB : $level";
        color = Colors.orange;
        break;
      case "KEORGANISASIAN" || "KEOR":
        text = "KEOR : $level";
        color = Colors.red;
        break;
      default:
        text = "Unknown";
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p8 / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade100, color.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.shade900),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(handleRouteChange);
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(handleRouteChange);
    super.dispose();
  }

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
                        const FaIcon(FontAwesomeIcons.fileExcel, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget._name,
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(color: Colors.grey, thickness: 1.0),
                              const SizedBox(height: 12.0),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  spacing: 12.0,
                                  children: [
                                    for (var data in widget._data.entries) getDivisionBadge(data),
                                  ],
                                ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: InkWell(
                                  onTap: widget._viewButton,
                                  child: Container(
                                    color: Colors.blue,
                                    child: const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSizes.p8),
                                        child: FaIcon(
                                          FontAwesomeIcons.eye,
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
