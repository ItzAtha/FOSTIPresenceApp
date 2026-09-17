import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/shared/provider/events_logs_notifier.dart';
import 'package:attendance_management/shared/provider/events_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../manager/bluetooth_manager.dart';
import '../../../../translations/locale_keys.g.dart';
import '../../../core/app_constants.dart';
import '../../../shared/provider/members_notifier.dart';

class PresenceMenuPage extends StatefulWidget {
  const PresenceMenuPage({super.key});

  @override
  State<StatefulWidget> createState() => _PresenceMenuPageState();
}

class _PresenceMenuPageState extends State<PresenceMenuPage> {
  late BluetoothManager btManager;
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
                            "Bluetooth Device",
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
                      "There no Bluetooth device are connected. Please connect to ESP32 Bluetooth first in Home action button [ + ] before register new member.",
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
          onTap: () => context.pushNamed(
            'member-presence-mode',
            pathParameters: {'presenceMode': 'PARTICIPANT'},
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  "Attendance as Participant",
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
          onTap: () => context.pushNamed(
            'member-presence-mode',
            pathParameters: {'presenceMode': 'COMMITTEE'},
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  "Attendance as Committee",
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
          onTap: () =>
              context.pushNamed('member-presence-mode', pathParameters: {'presenceMode': 'BPHI'}),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  "Attendance as BPHI",
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
          onTap: () =>
              context.pushNamed('member-presence-mode', pathParameters: {'presenceMode': 'MANUAL'}),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Text(
                  "Manual Attendance",
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
    btManager = BluetoothManager(context: context);

    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      btManager.sendBluetoothData(device, '2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(LocaleKeys.control_panel_page_title_presence.tr(context: context)),
        leading: BackButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BluetoothManager.getConnectedDevice == null ? noBTConnected() : showModeOptions(),
    );
  }
}

class PresenceModePage extends ConsumerStatefulWidget {
  const PresenceModePage({super.key, required this._attendanceMode});

  final String _attendanceMode;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PresenceModePageState();
}

class _PresenceModePageState extends ConsumerState<PresenceModePage> {
  bool isIdCardDetected = false;

  Timer? btTimerChecker;

  late BluetoothManager btManager;

  final TextEditingController memberIdCardController = TextEditingController();
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberNIMController = TextEditingController();
  final TextEditingController memberDivisionController = TextEditingController();

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
                            "Bluetooth Device",
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
                      "There no Bluetooth device are connected. Please connect to ESP32 Bluetooth first in Home action button [ + ] before register new member.",
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

  Widget noCardDetected() {
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
                        const FaIcon(FontAwesomeIcons.idCard, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            "Member Attendance",
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
                      "There no Member ID Card detected. Please tap the Member ID Card to RFID sensor to attendance and show data in here.",
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

  Widget cardDetected() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: <Widget>[
            Text("Member Profile", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 150.0,
              width: 150.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 150.0),
                child: CachedNetworkImage(
                  imageUrl: "https://cdn-icons-png.flaticon.com/128/3135/3135715.png",
                  imageBuilder: (context, imageProvider) => Container(
                    height: 120.0,
                    width: 120.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                  progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: CircularProgressIndicator(
                        value: downloadProgress.progress,
                        color: AppColors.secondary,
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, size: 32.0, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            TextField(
              readOnly: true,
              controller: memberIdCardController,
              decoration: const InputDecoration(
                labelText: "Member ID",
                prefixIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.idCard)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberNameController,
              decoration: const InputDecoration(
                labelText: "Member Name",
                prefixIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.solidUser)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberNIMController,
              decoration: const InputDecoration(
                labelText: "Member NIM",
                prefixIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.creditCard)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberDivisionController,
              decoration: const InputDecoration(
                labelText: "Member Division",
                prefixIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.sitemap)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> checkMemberData(String cardUID) async {
    final eventsList = await ref.read(eventsProvider.future);
    final eventsLogsList = await ref.read(eventsLogsProvider.future);
    final activeEvent = eventsList.where((e) => e.isActive).firstOrNull;

    print("Active Event: $activeEvent");
    if (activeEvent != null) {
      final activeEventLogs = eventsLogsList[activeEvent.eventId] ?? [];
      bool isUserNotAttendance = activeEventLogs.any((log) => log.cardId == cardUID);
      print("User with card UID $cardUID has not attended the active event: $isUserNotAttendance");
      return !isUserNotAttendance;
    }

    print("No active event found.");
    return false;
  }

  String getModeIndex(String mode) {
    switch (mode) {
      case 'PARTICIPANT':
        return '1';
      case 'COMMITTEE':
        return '2';
      case 'BPHI':
        return '3';
      case 'MANUAL':
        return '4';
      default:
        return '0';
    }
  }

  @override
  void initState() {
    super.initState();
    btManager = BluetoothManager(context: context);
    print(widget._attendanceMode);

    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      btManager.sendBluetoothData(device, getModeIndex(widget._attendanceMode));
    }

    btTimerChecker = Timer.periodic(const Duration(milliseconds: 500), (checkTimer) async {
      if (BluetoothManager.hasReceivedData) {
        String receivedData = BluetoothManager.getReceivedData;

        Map<String, dynamic> decodeData = {};
        Map<String, dynamic> data = {};

        try {
          decodeData = jsonDecode(receivedData);
          data = decodeData['data'];
        } catch (e) {
          print("Error decoding received data: $e");
        }

        final membersList = await ref.read(membersProvider.future);

        if (data['status'] == "CARD_DETECTED") {
          String cardUID = data['card_uid'];
          bool isValid = await checkMemberData(cardUID);

          BluetoothDevice? device = BluetoothManager.getConnectedDevice;
          if (device != null) {
            final member = membersList.where((m) => m.cardId == cardUID).firstOrNull;

            String encodeData = '';
            Map<String, dynamic> jsonPayload = {};
            if (member != null) {
              if (isValid) {
                jsonPayload = {
                  "message":
                      "User with card UID $cardUID is valid and has attended the active event.",
                  "data": {
                    "status": "USER_VALID_AND_NOT_ATTENDANCE",
                    "memberId": member.memberId,
                    "nama": member.name,
                    "nim": member.nim,
                    "divisi": member.division.aliases,
                  },
                };
                print("User with card UID $cardUID is valid and has attended the active event.");
              } else {
                jsonPayload.clear();
                jsonPayload = {
                  "message":
                      "User with card UID $cardUID has already attended the active event or event not exists.",
                  "data": {"status": "USER_ALREADY_ATTENDANCE_OR_EVENT_NOT_EXISTS"},
                };
                print(
                  "User with card UID $cardUID has already attended the active event or no active event.",
                );
              }
              encodeData = jsonEncode(jsonPayload);
              btManager.sendBluetoothData(device, encodeData);
              return;
            }

            jsonPayload.clear();
            jsonPayload = {
              "message": "No member found with card UID $cardUID.",
              "data": {"status": "USER_NOT_EXISTS"},
            };

            encodeData = jsonEncode(jsonPayload);
            btManager.sendBluetoothData(device, encodeData);
            print("No member found with card UID $cardUID.");
          } else {
            print("No Bluetooth device connected.");
          }
        } else if (data['status'] == "USER_SUCCESS_ATTENDANCE") {
          String cardUID = data['card_uid'];
          final member = membersList.firstWhere((m) => m.cardId == cardUID);

          setState(() => isIdCardDetected = true);
          memberIdCardController.text = member.cardId;
          memberNameController.text = member.name;
          memberNIMController.text = member.nim;
          memberDivisionController.text = member.division.aliases;

          Toastification().show(
            title: const Text("Member Attendance"),
            description: Text(
              "Member with Card Id $cardUID successfully to attend on active event.",
            ),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );

          Future.delayed(const Duration(seconds: 5), () {
            setState(() => isIdCardDetected = false);
            memberIdCardController.clear();
            memberNameController.clear();
            memberNIMController.clear();
            memberDivisionController.clear();
          });
        } else if (data['status'] == "USER_FAILED_ATTENDANCE") {
          String cardUID = data['card_uid'];

          Toastification().show(
            title: const Text("Member Attendance"),
            description: Text("Member with Card Id $cardUID failed to attend on active event."),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    btTimerChecker?.cancel();

    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      btManager.sendBluetoothData(device, 'cancel');
    }

    memberIdCardController.dispose();
    memberNameController.dispose();
    memberNIMController.dispose();
    memberDivisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            BluetoothManager.getConnectedDevice == null
                ? noBTConnected()
                : isIdCardDetected
                ? cardDetected()
                : noCardDetected(),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: BackButton(
                  onPressed: () {
                    context.pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
