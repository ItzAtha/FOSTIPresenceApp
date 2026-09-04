import 'package:attendance_management/features/dashboard/widgets/navbar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
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
          floatingActionButton: SpeedDial(
            elevation: 2.0,
            spacing: 3.0,
            icon: Icons.add,
            activeIcon: Icons.close,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            childPadding: const EdgeInsets.all(AppSizes.p8 / 2),
            spaceBetweenChildren: 4.0,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            labelTransitionBuilder: (widget, animation) =>
                ScaleTransition(scale: animation, child: widget),
            animationDuration: const Duration(milliseconds: 300),
            children: [
              SpeedDialChild(
                child: const FaIcon(FontAwesomeIcons.creditCard, size: 25.0),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                label: 'Attendance',
                labelStyle: Theme.of(context).textTheme.labelMedium,
                labelBackgroundColor: Theme.of(context).cardTheme.color,
                onTap: () {
                  // Handle add action
                },
              ),
              SpeedDialChild(
                child: const FaIcon(FontAwesomeIcons.userPlus, size: 20.0),
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                label: 'Add Member',
                labelStyle: Theme.of(context).textTheme.labelMedium,
                labelBackgroundColor: Theme.of(context).cardTheme.color,
                onTap: () {
                  // Handle add action
                },
              ),
              SpeedDialChild(
                child: const FaIcon(FontAwesomeIcons.calendarPlus, size: 25.0),
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                label: 'Add Event',
                labelStyle: Theme.of(context).textTheme.labelMedium,
                labelBackgroundColor: Theme.of(context).cardTheme.color,
                onTap: () {
                  // Handle add action
                },
              ),
            ],
          ),
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
