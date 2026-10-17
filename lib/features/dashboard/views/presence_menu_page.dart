import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/core/translations/locale_keys.g.dart';
import 'package:attendance_management/routes/app_router.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:attendance_management/shared/provider/events_logs_notifier.dart';
import 'package:attendance_management/shared/provider/events_notifier.dart';
import 'package:attendance_management/shared/service/ble_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_constants.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/members_data_factory.dart';
import '../../../shared/provider/members_notifier.dart';
import '../../../shared/service/stream_listener.dart';

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

enum ManualAttendanceStatus { success, failed, timeout, none }

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
  String callbackMsg = "";

  bool isIdCardDetected = false;
  bool isSuccessAttendance = false;
  bool isManualAttendance = false;
  bool isLoadingToAttendance = false;
  ManualAttendanceStatus manualAttendanceStatus = ManualAttendanceStatus.none;

  Timer? btTimerChecker;
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  late MembersDataFactory membersData;
  late BleService bleService;

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
        FocusManager.instance.primaryFocus?.unfocus();

        String nim = memberNIMController.text.trim();
        bool hasError = false;

        BluetoothDevice? device = bleService.connectedDevice;
        if (device != null) {
          setState(() => isLoadingToAttendance = true);
          final validation = await validateMemberData(nim);

          String encodeData = '';
          Map<String, dynamic> jsonPayload = {};

          MemberModel? member = validation.data;
          switch (validation.status) {
            case ValidateStatus.member_not_yet_attendance:
              jsonPayload = {
                "message": "Member with NIM ${member?.nim} is not yet attended the active event.",
                "status": "MEMBER_NOT_YET_ATTENDANCE",
                "data": {
                  "memberId": member?.memberId,
                  "nama": member?.name,
                  "nim": member?.nim,
                  "divisi": member?.division.aliases,
                },
              };

              print("Member with NIM ${member?.nim} is not yet attended the active event.");
              break;
            case ValidateStatus.member_already_attendance:
              setState(() {
                hasError = true;
                isLoadingToAttendance = false;
              });

              jsonPayload = {
                "message": "Member with NIM ${member?.nim} has already attended the active event.",
                "status": "MEMBER_ALREADY_ATTENDANCE",
              };

              if (!mounted) return;

              Toastification().show(
                title: Text(LocaleKeys.notification_attendance_title_manual.tr(context: context)),
                description: Text(
                  LocaleKeys.notification_attendance_description_manual_has_attend.tr(
                    context: context,
                    namedArgs: {'nim': ?member?.nim},
                  ),
                ),
                type: ToastificationType.error,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );

              print("Member with NIM ${member?.nim} has already attended the active event.");
              break;
            case ValidateStatus.member_not_exists:
              setState(() {
                hasError = true;
                isLoadingToAttendance = false;
              });

              jsonPayload = {
                "message": "No member found with NIM $nim.",
                "status": "MEMBER_NOT_EXISTS",
              };

              if (!mounted) return;

              Toastification().show(
                title: Text(LocaleKeys.notification_attendance_title_manual.tr(context: context)),
                description: Text(
                  LocaleKeys.notification_attendance_description_manual_not_exists.tr(
                    context: context,
                    namedArgs: {'nim': nim},
                  ),
                ),
                type: ToastificationType.error,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );

              print("No member found with NIM $nim.");
              break;
            case ValidateStatus.event_not_exists:
              setState(() {
                hasError = true;
                isLoadingToAttendance = false;
              });

              jsonPayload = {"message": "No active event found.", "status": "EVENT_NOT_EXISTS"};

              if (!mounted) return;

              Toastification().show(
                title: Text(LocaleKeys.notification_attendance_title_manual.tr(context: context)),
                description: Text(
                  LocaleKeys.notification_attendance_description_no_active_event.tr(
                    context: context,
                  ),
                ),
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
          bleService.sendBluetoothData(device, encodeData);

          if (hasError) return;

          Timer? checkTimer;
          final completer = Completer<bool>();

          final timeoutTimer = Timer(const Duration(minutes: 1), () {
            if (!completer.isCompleted) {
              checkTimer?.cancel();
              completer.completeError(TimeoutException("Request timeout"));
            }
          });

          checkTimer = Timer.periodic(const Duration(milliseconds: 500), (checkTimer) {
            if (manualAttendanceStatus == ManualAttendanceStatus.success) {
              checkTimer.cancel();
              timeoutTimer.cancel();

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            } else if (manualAttendanceStatus == ManualAttendanceStatus.failed) {
              checkTimer.cancel();
              timeoutTimer.cancel();

              if (!completer.isCompleted) {
                completer.complete(false);
              }
            } else if (manualAttendanceStatus == ManualAttendanceStatus.timeout) {
              checkTimer.cancel();
              timeoutTimer.cancel();

              if (!completer.isCompleted) {
                completer.completeError(TimeoutException("Request timeout"));
              }
            }
          });

          try {
            bool isSuccess = await completer.future;
            ToastificationType notificationType = isSuccess
                ? ToastificationType.success
                : ToastificationType.error;

            if (!mounted) return;

            Toastification().show(
              title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
              description: Text(callbackMsg),
              type: notificationType,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );

            if (isSuccess) memberNIMController.clear();
          } on TimeoutException {
            if (!mounted) return;

            Toastification().show(
              title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
              description: Text(
                LocaleKeys.notification_attendance_description_request_timeout.tr(context: context),
              ),
              type: ToastificationType.error,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );
          } finally {
            memberNIMController.clear();

            setState(() {
              callbackMsg = "";
              isLoadingToAttendance = false;
            });

            manualAttendanceStatus = ManualAttendanceStatus.none;
          }
        } else {
          Toastification().show(
            title: Text(LocaleKeys.notification_bluetooth_title.tr(context: context)),
            description: Text(
              LocaleKeys.notification_bluetooth_description_no_device_connected.tr(
                context: context,
              ),
            ),
            type: ToastificationType.warning,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
          print("No Bluetooth device connected. Cannot send data.");
        }
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

  Widget noMemberAttendance() {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            margin: const EdgeInsets.all(AppSizes.p16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const FaIcon(FontAwesomeIcons.idCard, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            LocaleKeys.alert_card_no_card_title.tr(context: context),
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
                      LocaleKeys.alert_card_no_card_description_on_attendance.tr(context: context),
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (isIdCardDetected)
          ValueListenableBuilder(
            valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
            builder: (_, mode, child) {
              return Positioned.fill(
                child: Container(
                  color: mode == AdaptiveThemeMode.light
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mode == AdaptiveThemeMode.light
                            ? AppColors.secondary
                            : AppColors.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget showMemberProfile() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: <Widget>[
            Text(
              LocaleKeys.attendance_page_mode_page_title.tr(context: context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.6),
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
              decoration: InputDecoration(
                labelText: LocaleKeys.attendance_page_mode_page_title.tr(context: context),
                prefixIcon: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.idCard)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberNameController,
              decoration: InputDecoration(
                labelText: LocaleKeys.attendance_page_mode_page_name_field.tr(context: context),
                prefixIcon: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.solidUser)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberNIMController,
              decoration: InputDecoration(
                labelText: LocaleKeys.attendance_page_mode_page_nim_field.tr(context: context),
                prefixIcon: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.creditCard)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              readOnly: true,
              controller: memberDivisionController,
              decoration: InputDecoration(
                labelText: LocaleKeys.attendance_page_mode_page_division_field.tr(context: context),
                prefixIcon: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: FaIcon(FontAwesomeIcons.sitemap)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
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
            Text(
              LocaleKeys.attendance_page_mode_page_manual_title.tr(context: context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                        LocaleKeys.attendance_page_mode_page_manual_information.tr(
                          context: context,
                        ),
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
                    controller: memberNIMController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.attendance_page_mode_page_nim_field_title.tr(
                        context: context,
                      ),
                      hintText: "L200250001",
                      icon: const FaIcon(FontAwesomeIcons.idCard, size: 24.0),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (String? value) {
                      bool isValidFormat = RegExp(r'^[A-Z][0-9]+$').hasMatch(value ?? '');

                      if (value.toString().isEmpty) {
                        return LocaleKeys.attendance_page_mode_page_nim_field_required_empty.tr(
                          context: context,
                        );
                      } else if (!isValidFormat ||
                          value.toString().length < 10 ||
                          value.toString().length > 10) {
                        return LocaleKeys.attendance_page_mode_page_nim_field_required_invalid.tr(
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
                                        : AppColors.secondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            },
                          )
                        : Text(
                            LocaleKeys.attendance_page_mode_page_manual_button.tr(context: context),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
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
    bleService = BleService();

    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, getModeIndex(widget._attendanceMode));
    }

    if (getModeIndex(widget._attendanceMode) == '4') {
      setState(() => isManualAttendance = true);

      membersData = MembersDataFactory();
      membersData.loadExcelData().catchError((error) {
        print("Error loading FOSTI members data excel: $error");
        return false;
      });
    }
  }

  @override
  void dispose() {
    btTimerChecker?.cancel();

    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, 'cancel');

      if (getModeIndex(widget._attendanceMode) == '4') {
        bleService.sendBluetoothData(device, 'cancel');
      }
    }

    memberIdCardController.dispose();
    memberNameController.dispose();
    memberNIMController.dispose();
    memberDivisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamListener(
      stream: bleService.dataStream,
      onData: (context, receivedData) async {
        Map<String, dynamic> decodedData = {};
        Map<String, dynamic> data = {};

        print("Received data: $receivedData");

        try {
          decodedData = jsonDecode(receivedData);
          data = decodedData['data'];
        } catch (e) {
          print("Error decoding received data: $e");
        }

        if (decodedData['status'] == "CARD_DETECTED") {
          String cardUID = data['cardId'];

          BluetoothDevice? device = bleService.connectedDevice;
          if (device != null) {
            setState(() => isIdCardDetected = true);
            Toastification().show(
              title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
              description: Text(
                LocaleKeys.notification_attendance_description_main_card_detected.tr(
                  context: context,
                ),
              ),
              type: ToastificationType.info,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );

            final validation = await validateMemberData(cardUID);

            String encodeData = '';
            Map<String, dynamic> jsonPayload = {};

            switch (validation.status) {
              case ValidateStatus.member_not_yet_attendance:
                MemberModel? member = validation.data;

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
                setState(() => isIdCardDetected = false);

                jsonPayload = {
                  "message": "Member with Card Id $cardUID has already attended the active event.",
                  "status": "MEMBER_ALREADY_ATTENDANCE",
                };

                if (!context.mounted) return;

                Toastification().show(
                  title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
                  description: Text(
                    LocaleKeys.notification_attendance_description_main_has_attend.tr(
                      context: context,
                      namedArgs: {'cardId': cardUID},
                    ),
                  ),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                print("Member with Card Id $cardUID has already attended the active event.");
                break;
              case ValidateStatus.member_not_exists:
                setState(() => isIdCardDetected = false);

                jsonPayload = {
                  "message": "No member found with Card Id $cardUID.",
                  "status": "MEMBER_NOT_EXISTS",
                };

                if (!context.mounted) return;

                Toastification().show(
                  title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
                  description: Text(
                    LocaleKeys.notification_attendance_description_main_not_exists.tr(
                      context: context,
                      namedArgs: {'cardId': cardUID},
                    ),
                  ),
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );

                print("No member found with Card Id $cardUID.");
                break;
              case ValidateStatus.event_not_exists:
                setState(() => isIdCardDetected = false);

                jsonPayload = {"message": "No active event found.", "status": "EVENT_NOT_EXISTS"};

                if (!context.mounted) return;

                Toastification().show(
                  title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
                  description: Text(
                    LocaleKeys.notification_attendance_description_no_active_event.tr(
                      context: context,
                    ),
                  ),
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
            bleService.sendBluetoothData(device, encodeData);
          } else {
            Toastification().show(
              title: Text(LocaleKeys.notification_bluetooth_title.tr(context: context)),
              description: Text(
                LocaleKeys.notification_bluetooth_description_no_device_connected.tr(
                  context: context,
                ),
              ),
              type: ToastificationType.warning,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );
            print("No Bluetooth device connected. Cannot send data.");
          }
        } else if (decodedData['status'] == "MEMBER_SUCCESS_MANUAL_ATTENDANCE") {
          callbackMsg = decodedData['message'];
          manualAttendanceStatus = ManualAttendanceStatus.success;
        } else if (decodedData['status'] == "MEMBER_FAILED_MANUAL_ATTENDANCE") {
          callbackMsg = decodedData['message'];
          manualAttendanceStatus = ManualAttendanceStatus.failed;
        } else if (decodedData['status'] == "TIMEOUT_NO_DATA") {
          Toastification().show(
            title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
            description: Text(
              LocaleKeys.notification_attendance_description_request_timeout.tr(context: context),
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        } else {
          ToastificationType notificationType = ToastificationType.error;
          if (decodedData['status'] == "MEMBER_SUCCESS_ATTENDANCE") {
            String cardUID = data['cardId'];
            final membersList = await ref.read(membersProvider.future);
            final member = membersList.firstWhere((m) => m.cardId == cardUID);

            memberIdCardController.text = member.cardId;
            memberNameController.text = member.name;
            memberNIMController.text = member.nim;
            memberDivisionController.text = member.division.aliases;

            setState(() => isSuccessAttendance = true);

            ref.invalidate(eventsLogsProvider);
            notificationType = ToastificationType.success;

            Future.delayed(const Duration(seconds: 5), () {
              if (!mounted) return;

              setState(() => isSuccessAttendance = false);
              memberIdCardController.clear();
              memberNameController.clear();
              memberNIMController.clear();
              memberDivisionController.clear();
            });
          }

          setState(() => isIdCardDetected = false);

          if (!context.mounted) return;

          Toastification().show(
            title: Text(LocaleKeys.notification_attendance_title_main.tr(context: context)),
            description: Text(decodedData['message']),
            type: notificationType,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              ValueListenableBuilder(
                valueListenable: bleService.activeConnectionState,
                builder: (context, state, child) {
                  return state == BleConnectionState.connected
                      ? isManualAttendance
                            ? showManualAttendance()
                            : isSuccessAttendance
                            ? showMemberProfile()
                            : noMemberAttendance()
                      : noBTConnected();
                },
              ),
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
      ),
    );
  }
}
