import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/shared/models/member_model.dart';
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
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/members_data_factory.dart';
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
  void dispose() {
    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      btManager.sendBluetoothData(device, 'cancel');
    }
    super.dispose();
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

enum ValidateStatus {
  member_not_yet_attendance,
  member_already_attendance,
  member_not_exists,
  event_not_exists,
}

class PresenceModePage extends ConsumerStatefulWidget {
  const PresenceModePage({super.key, required this._attendanceMode});

  final String _attendanceMode;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PresenceModePageState();
}

class _PresenceModePageState extends ConsumerState<PresenceModePage> {
  bool isIdCardDetected = false;
  bool isManualAttendance = false;
  bool isLoadingToAttendance = false;

  Timer? btTimerChecker;
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  late MembersData membersData;
  late BluetoothManager btManager;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController memberIdCardController = TextEditingController();
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberNIMController = TextEditingController();
  final TextEditingController memberDivisionController = TextEditingController();

  Future<({ValidateStatus status, MemberModel? data})> validateMemberData(String memberId) async {
    final membersList = await ref.read(membersProvider.future);
    final eventsList = await ref.read(eventsProvider.future);
    final eventsLogsList = await ref.read(eventsLogsProvider.future);
    final activeEvent = eventsList.where((e) => e.isActive).firstOrNull;

    if (activeEvent != null) {
      final activeEventLogs = eventsLogsList[activeEvent.eventId] ?? [];
      final member = membersList
          .where((m) => m.cardId == memberId || m.nim == memberId)
          .firstOrNull;

      if (member != null) {
        final isMemberAlreadyAttendance = activeEventLogs.any((log) => log.cardId == member.cardId);
        print(isMemberAlreadyAttendance);
        return (
        status: isMemberAlreadyAttendance
            ? ValidateStatus.member_already_attendance
            : ValidateStatus.member_not_yet_attendance,
        data: member,
        );
      }

      return (status: ValidateStatus.member_not_exists, data: null);
    }

    return (status: ValidateStatus.event_not_exists, data: null);
  }

  Future<void> validateFormInput() async {
    FormState? form = formKey.currentState;

    if (form != null) {
      if (form.validate()) {
        setState(() => isLoadingToAttendance = true);

        final membersList = await ref.read(membersProvider.future);
        final eventsList = await ref.read(eventsProvider.future);
        final eventsLogsList = await ref.read(eventsLogsProvider.future);
        final activeEvent = eventsList.where((e) => e.isActive).firstOrNull;

        String name = memberNameController.text.trim();
        String nim = memberNIMController.text.trim();

        String encodeData = '';
        Map<String, dynamic> jsonPayload = {};

        BluetoothDevice? device = BluetoothManager.getConnectedDevice;
        if (device == null) {
          Toastification().show(
            title: const Text("Bluetooth Device"),
            description: const Text("No Bluetooth device connected. Cannot send data."),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
          print("No Bluetooth device connected. Cannot send data.");
          setState(() => isLoadingToAttendance = false);
          return;
        }

        if (activeEvent != null) {
          print(activeEvent);
          final member = membersList.where((m) => m.nim == nim).firstOrNull;
          print(member);
          if (member != null) {
            final activeEventLogs = eventsLogsList[activeEvent.eventId] ?? [];
            print(activeEventLogs);
            bool isMemberNotYetAttendance = activeEventLogs.any((log) {
              print(log.cardId);
              print(member.cardId);
              return log.cardId == member.cardId;
            });

            if (isMemberNotYetAttendance) {
              jsonPayload = {
                "message":
                    "Member with card UID ${member.cardId} is valid and hasn't attend to active event.",
                "data": {
                  "status": "MEMBER_NOT_YET_ATTENDANCE",
                  "memberId": member.memberId,
                  "cardUID": member.cardId,
                  "nama": member.name,
                  "nim": member.nim,
                },
              };

              encodeData = jsonEncode(jsonPayload);
              btManager.sendBluetoothData(device, encodeData);
              print(
                "Member with card UID ${member.cardId} is valid and hasn't attend to active event.",
              );

              Timer? checkTimer;
              final completer = Completer<bool>();

              final timeoutTimer = Timer(const Duration(seconds: 30), () {
                if (!completer.isCompleted) {
                  setState(() => isLoadingToAttendance = false);
                  checkTimer?.cancel();
                  completer.completeError(TimeoutException("Request timeout"));
                }
              });

              checkTimer = Timer.periodic(const Duration(milliseconds: 500), (checkTimer) {
                if (BluetoothManager.hasReceivedData) {
                  String receivedData = BluetoothManager.getReceivedData;

                  Map<String, dynamic> decodeData = {};

                  try {
                    decodeData = jsonDecode(receivedData);
                  } catch (e) {
                    print("Error decoding received data: $e");
                  }

                  if (decodeData['status'] == "MEMBER_SUCCESS_MANUAL_ATTENDANCE") {
                    checkTimer.cancel();
                    timeoutTimer.cancel();

                    if (!completer.isCompleted) {
                      completer.complete(true);
                    }
                  } else if (decodeData['status'] == "MEMBER_FAILED_MANUAL_ATTENDANCE") {
                    checkTimer.cancel();
                    timeoutTimer.cancel();

                    if (!completer.isCompleted) {
                      completer.complete(false);
                    }
                  }
                }
              });

              bool isSuccess = await completer.future;
              if (isSuccess) {
                Toastification().show(
                  title: const Text("Member Manual Attendance"),
                  description: Text(
                    "Successfully force member to attendance with Card ID: ${member.cardId}",
                  ),
                  type: ToastificationType.success,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                memberNameController.clear();
                memberNIMController.clear();
              } else {
                Toastification().show(
                  title: const Text("Member Manual Attendance"),
                  description: Text(
                    "Failed to force member to attendance. Member already attendance with Card ID: ${member.cardId}",
                  ),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );
              }

              setState(() => isLoadingToAttendance = false);
              return;
            } else {
              jsonPayload = {
                "message":
                    "Member with card UID ${member.cardId} has already attended the active event.",
                "data": {"status": "MEMBER_ALREADY_ATTENDANCE"},
              };

              Toastification().show(
                title: const Text("Member Manual Attendance"),
                description: Text(
                  "Member with card UID ${member.cardId} has already attended the active event.",
                ),
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );
            }
          } else {
            jsonPayload = {
              "message": "No member found with NIM $nim.",
              "data": {"status": "MEMBER_NOT_EXISTS"},
            };

            Toastification().show(
              title: const Text("Member Manual Attendance"),
              description: Text("Member with NIM $nim is not found."),
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );
          }
        } else {
          jsonPayload = {
            "message": "No active event available.",
            "data": {"status": "NO_ACTIVE_EVENT"},
          };

          Toastification().show(
            title: const Text("Member Manual Attendance"),
            description: const Text("No active event available."),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }

        encodeData = jsonEncode(jsonPayload);
        btManager.sendBluetoothData(device, encodeData);
      }
    }
  }

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

  Widget showManualAttendance() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: <Widget>[
            Text("Manual Attendance", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.8), width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const FaIcon(FontAwesomeIcons.circleInfo, size: 24.0),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        "You can just write a Member NIM to automatically filling the field or, if it doesn't exists, write it manually.",
                        textAlign: TextAlign.justify,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48.0),
            Form(
              key: formKey,
              canPop: false,
              autovalidateMode: AutovalidateMode.onUnfocus,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: memberNameController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.member_page_dialog_field_name.tr(context: context),
                      icon: const FaIcon(FontAwesomeIcons.user, size: 24.0),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (String? value) {
                      if (value.toString().isEmpty) {
                        return LocaleKeys.member_page_dialog_validation_name_required.tr(
                          context: context,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: memberNIMController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.member_page_dialog_field_nim.tr(context: context),
                      hintText: "L200250001",
                      icon: const FaIcon(FontAwesomeIcons.idCard, size: 24.0),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) async {
                      debouncer.run(() {
                        final memberData = membersData.findStudentByNIM(value);
                        print("Found: $memberData");

                        setState(() => memberNameController.text = memberData[1]);
                      });
                    },
                    validator: (String? value) {
                      bool isValidFormat = RegExp(r'^[A-Z][0-9]+$').hasMatch(value ?? '');

                      if (value.toString().isEmpty) {
                        return LocaleKeys.member_page_dialog_validation_nim_required_empty.tr(
                          context: context,
                        );
                      } else if (!isValidFormat ||
                          value.toString().length < 10 ||
                          value.toString().length > 10) {
                        return LocaleKeys.member_page_dialog_validation_nim_required_invalid.tr(
                          context: context,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => validateFormInput(),
                    child: isLoadingToAttendance
                        ? ValueListenableBuilder(
                            valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                            builder: (_, mode, child) {
                              return SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    mode == AdaptiveThemeMode.light
                                        ? AppColors.secondary
                                        : AppColors.secondary.withValues(alpha: 0.8),
                                  ),
                                ),
                              );
                            },
                          )
                        : Text("Attendance Member", style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      btManager.sendBluetoothData(device, getModeIndex(widget._attendanceMode));
    }

    if (getModeIndex(widget._attendanceMode) == '4') {
      setState(() => isManualAttendance = true);

      membersData = MembersData();
      membersData.loadData().catchError((error) {
        print("Error loading FOSTI members data excel: $error");
        return false;
      });
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

        if (decodeData['status'] == "CARD_DETECTED") {
          String cardUID = data['card_uid'];
          final validation = await validateMemberData(cardUID);

          BluetoothDevice? device = BluetoothManager.getConnectedDevice;
          if (device != null) {
            String encodeData = '';
            Map<String, dynamic> jsonPayload = {};

            MemberModel? member = validation.data;
            switch (validation.status) {
              case ValidateStatus.member_not_yet_attendance:
                jsonPayload = {
                  "message":
                      "Member with Card Id ${member?.cardId} is not yet attended the active event.",
                  "status": "MEMBER_NOT_YET_ATTENDANCE",
                  "data": {
                    "memberId": member?.memberId,
                    "nama": member?.name,
                    "nim": member?.nim,
                    "divisi": member?.division.aliases,
                  },
                };

                print(
                  "Member with Card Id ${member?.cardId} is not yet attended the active event.",
                );
                break;
              case ValidateStatus.member_already_attendance:
                jsonPayload = {
                  "message":
                      "Member with Card Id ${member?.cardId} has already attended the active event.",
                  "status": "MEMBER_ALREADY_ATTENDANCE",
                };

                Toastification().show(
                  title: const Text("Member Attendance"),
                  description: Text(
                    "Member with Card Id ${member?.cardId} has already attended the active event.",
                  ),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                print(
                  "Member with Card Id ${member?.cardId} has already attended the active event.",
                );
                break;
              case ValidateStatus.member_not_exists:
                jsonPayload = {
                  "message": "No member found with Card Id $cardUID.",
                  "status": "MEMBER_NOT_EXISTS",
                };

                Toastification().show(
                  title: const Text("Member Attendance"),
                  description: Text("Member with Card Id ${member?.cardId} is not exists."),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                print("No member found with Card Id $cardUID.");
                break;
              case ValidateStatus.event_not_exists:
                jsonPayload = {"message": "No active event found.", "status": "EVENT_NOT_EXISTS"};

                Toastification().show(
                  title: const Text("Member Attendance"),
                  description: const Text("No active event found."),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                print("No active event found.");
                break;
            }

            encodeData = jsonEncode(jsonPayload);
            btManager.sendBluetoothData(device, encodeData);
          } else {
            Toastification().show(
              title: const Text("Bluetooth Device"),
              description: const Text("No Bluetooth device connected. Cannot send data."),
              type: ToastificationType.warning,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );
            print("No Bluetooth device connected. Cannot send data.");
          }
        } else {
          ToastificationType notificationType = ToastificationType.error;
          if (decodeData['status'] == "MEMBER_SUCCESS_ATTENDANCE") {
            String cardUID = data['card_uid'];
            final member = membersList.firstWhere((m) => m.cardId == cardUID);

            memberIdCardController.text = member.cardId;
            memberNameController.text = member.name;
            memberNIMController.text = member.nim;
            memberDivisionController.text = member.division.aliases;
            setState(() => isIdCardDetected = true);

            ref.invalidate(eventsLogsProvider);
            notificationType = ToastificationType.success;

            Future.delayed(const Duration(seconds: 5), () {
              if (!mounted) return;

              setState(() => isIdCardDetected = false);
              memberIdCardController.clear();
              memberNameController.clear();
              memberNIMController.clear();
              memberDivisionController.clear();
            });
          }

          Toastification().show(
            title: const Text("Member Attendance"),
            description: Text(decodeData['message']),
            type: notificationType,
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
                : isManualAttendance
                ? showManualAttendance()
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
