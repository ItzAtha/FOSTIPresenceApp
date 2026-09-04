import 'dart:ui';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';

class NavbarScope extends InheritedWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelect;

  const NavbarScope({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelect,
    required super.child,
  });

  static NavbarScope of(BuildContext context) {
    final NavbarScope? result = context.dependOnInheritedWidgetOfExactType<NavbarScope>();
    assert(result != null, 'No NavbarScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant NavbarScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex;
  }
}

class DestinationScope extends InheritedWidget {
  final int index;

  const DestinationScope({super.key, required this.index, required super.child});

  static DestinationScope of(BuildContext context) {
    final DestinationScope? result = context.dependOnInheritedWidgetOfExactType<DestinationScope>();
    assert(result != null, 'No DestinationScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant DestinationScope oldWidget) {
    return index != oldWidget.index;
  }
}

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({
    super.key,
    required this._selectedIndex,
    required this._onDestinationSelect,
    required this._destinations,
  });

  final int _selectedIndex;
  final ValueChanged<int> _onDestinationSelect;
  final List<Widget> _destinations;

  List<Widget> _generateNavbarIcons(BuildContext context) {
    List<Widget> navbarIcons = [];
    final navbarIconsDestination = _destinations
        .asMap()
        .map(
          (index, destination) =>
              MapEntry(index, DestinationScope(index: index, child: destination)),
        )
        .values
        .toList();

    for (int i = 0; i < navbarIconsDestination.length; i++) {
      if (i == (navbarIconsDestination.length / 2).floor()) {
        SpeedDial actionButton = SpeedDial(
          elevation: 2.0,
          spacing: 3.0,
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
              child: const FaIcon(FontAwesomeIcons.clipboardList),
              label: 'Activity',
              onTap: () {
                // Handle add action
              },
            ),
            SpeedDialChild(
              child: const FaIcon(FontAwesomeIcons.code, size: 20.0),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              label: 'Code Sandbox',
              labelStyle: Theme.of(context).textTheme.labelMedium,
              labelBackgroundColor: Theme.of(context).cardTheme.color,
              labelShadow: [],
              onTap: () {
                // DebugLogger(message: 'Code Sandbox', level: LogLevel.debug).log();
              },
            ),
          ],
          child: const FaIcon(FontAwesomeIcons.expand),
        );

        navbarIcons.add(const SizedBox(width: 8.0));
        navbarIcons.add(actionButton);
        navbarIcons.add(const SizedBox(width: 8.0));
      }
      navbarIcons.add(navbarIconsDestination[i]);
    }

    return navbarIcons;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Card(
        elevation: 1.25,
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.largeRounded)),
        ),
        child: SizedBox(
          height: 65.0,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.largeRounded)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p8,
                  vertical: AppSizes.p8 / 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.largeRounded)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                ),
                child: NavbarScope(
                  selectedIndex: _selectedIndex,
                  onDestinationSelect: _onDestinationSelect,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _generateNavbarIcons(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DestinationNavbarWidget extends StatelessWidget {
  final String label;
  final Icon icon;

  const DestinationNavbarWidget({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final navbarScope = NavbarScope.of(context);
    final destinationScope = DestinationScope.of(context);
    bool isDestinationSelected = navbarScope.selectedIndex == destinationScope.index;

    return SizedBox(
      width: 72.0,
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.mediumRounded)),
        ),
        color: isDestinationSelected ? Colors.grey.withValues(alpha: 0.3) : Colors.transparent,
        child: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              const SizedBox(height: 4.0),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          onTap: () {
            navbarScope.onDestinationSelect(destinationScope.index);
          },
        ),
      ),
    );
  }
}
