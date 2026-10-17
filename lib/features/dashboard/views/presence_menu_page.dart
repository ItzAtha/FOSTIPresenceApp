import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/core/translations/locale_keys.g.dart';
import 'package:attendance_management/routes/app_router.dart';
import 'package:attendance_management/shared/service/ble_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';

class PresenceMenuPage extends StatefulWidget {
  const PresenceMenuPage({super.key});

  @override
  State<StatefulWidget> createState() => _PresenceMenuPageState();
}

class _PresenceMenuPageState extends State<PresenceMenuPage> {
  late BleService bleService;
  final carouselController = PageController(viewportFraction: 0.7);

  Widget noBTConnected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(AppSizes.p16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const FaIcon(FontAwesomeIcons.bluetooth, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            LocaleKeys.alert_card_no_bluetooth_title.tr(context: context),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8.0),
                    Text(
                      LocaleKeys.alert_card_no_bluetooth_description_on_attendance.tr(
                        context: context,
                      ),
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget showModeOptions() {
    final modeOptions = [
      Card(
        elevation: 5.0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => const MemberAttendanceModeRoute(attendanceMode: 'PARTICIPANT').push(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  LocaleKeys.attendance_page_mode_options_as_participant.tr(context: context),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                ValueListenableBuilder(
                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                  builder: (_, mode, child) {
                    return Image.asset(
                      "assets/participant-attendance-icon.png",
                      height: 160.0,
                      color: mode == AdaptiveThemeMode.light
                          ? AppColors.iconLight
                          : AppColors.iconDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      Card(
        elevation: 5.0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => const MemberAttendanceModeRoute(attendanceMode: 'COMMITTEE').push(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  LocaleKeys.attendance_page_mode_options_as_committee.tr(context: context),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                ValueListenableBuilder(
                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                  builder: (_, mode, child) {
                    return Image.asset(
                      "assets/committee-attendance-icon.png",
                      height: 160.0,
                      color: mode == AdaptiveThemeMode.light
                          ? AppColors.iconLight
                          : AppColors.iconDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        elevation: 5.0,
        child: InkWell(
          onTap: () => const MemberAttendanceModeRoute(attendanceMode: 'BPHI').push(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  LocaleKeys.attendance_page_mode_options_as_bphi.tr(context: context),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                ValueListenableBuilder(
                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                  builder: (_, mode, child) {
                    return Image.asset(
                      "assets/bphi-attendance-icon.png",
                      height: 160.0,
                      color: mode == AdaptiveThemeMode.light
                          ? AppColors.iconLight
                          : AppColors.iconDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      Card(
        elevation: 5.0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => const MemberAttendanceModeRoute(attendanceMode: 'MANUAL').push(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  LocaleKeys.attendance_page_mode_options_manual.tr(context: context),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                ValueListenableBuilder(
                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                  builder: (_, mode, child) {
                    return Image.asset(
                      "assets/manual-attendance-icon.png",
                      height: 160.0,
                      color: mode == AdaptiveThemeMode.light
                          ? AppColors.iconLight
                          : AppColors.iconDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ExpandablePageView.builder(
            controller: carouselController,
            clipBehavior: Clip.none,
            itemCount: modeOptions.length,
            itemBuilder: (_, index) {
              if (!carouselController.position.haveDimensions) {
                return const SizedBox();
              }
              return AnimatedBuilder(
                animation: carouselController,
                builder: (_, _) => Transform.scale(
                  scale: max(0.8, 1 - (carouselController.page! - index).abs() * 0.2),
                  child: modeOptions[index],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    bleService = BleService();

    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, '2');
    }
  }

  @override
  void dispose() {
    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, 'cancel');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(LocaleKeys.attendance_page_title.tr(context: context)),
        leading: BackButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: bleService.activeConnectionState,
        builder: (context, state, child) {
          return state == BleConnectionState.connected ? showModeOptions() : noBTConnected();
        },
      ),
    );
  }
}
