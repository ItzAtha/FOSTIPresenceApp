import 'package:attendance_management/features/dashboard/widgets/navbar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../translations/locale_keys.g.dart';

class BasePages extends StatefulWidget {
  const BasePages({super.key, required this._navigationShell});

  final StatefulNavigationShell _navigationShell;

  @override
  State<StatefulWidget> createState() => _BasePagesState();
}

class _BasePagesState extends State<BasePages> {
  bool canCloseApp = false;
  DateTime? currentBackPressTime;

  void onPopInvoked(bool canPop, Object? result) {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Toastification().show(
        context: context,
        title: const Text(LocaleKeys.exit_alert_title).tr(context: context),
        description: const Text(LocaleKeys.exit_alert_desc).tr(context: context),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 500),
      );

      // Disable pop invoke and close the toast after 2s timeout
      Future.delayed(const Duration(seconds: 2), () => setState(() => canCloseApp = false));
      setState(() => canCloseApp = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canCloseApp,
      onPopInvokedWithResult: onPopInvoked,
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: NavbarWidget(
          selectedIndex: widget._navigationShell.currentIndex,
          onDestinationSelect: (index) {
            widget._navigationShell.goBranch(
              index,
              initialLocation: index == widget._navigationShell.currentIndex,
            );
          },
          destinations: [
            const DestinationNavbarWidget(label: 'Home', icon: FaIcon(FontAwesomeIcons.solidHouse)),
            const DestinationNavbarWidget(label: 'Members', icon: FaIcon(FontAwesomeIcons.users)),
            const DestinationNavbarWidget(
              label: 'Events',
              icon: FaIcon(FontAwesomeIcons.calendarDays),
            ),
            const DestinationNavbarWidget(label: 'Settings', icon: FaIcon(FontAwesomeIcons.gear)),
          ],
        ),
        body: SafeArea(bottom: false, child: widget._navigationShell),
      ),
    );
  }
}
