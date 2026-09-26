import 'dart:async';
import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/shared/provider/members_notifier.dart';
import 'package:attendance_management/shared/service/stream_listener.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/members_data_factory.dart';
import '../../../../translations/locale_keys.g.dart';
import '../../../core/app_constants.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/service/ble_service.dart';

enum RegisterStatus { success, failed, timeout, none }

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  String callbackMsg = "";

  bool isIdCardDetected = false;
  bool isLoadingToRegister = false;

  Divisions? selectedDivision;
  RegisterStatus registerStatus = RegisterStatus.none;
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  late MembersData membersData;
  late BleService bleService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController memberIdCardController = TextEditingController();
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberNIMController = TextEditingController();

  Future<void> validateFormInput() async {
    FormState? form = formKey.currentState;

    if (form != null) {
      if (form.validate()) {
        setState(() => isLoadingToRegister = true);

        String cardId = memberIdCardController.text.trim();
        String name = memberNameController.text.trim();
        String nim = memberNIMController.text.trim();
        String divisi = selectedDivision?.aliases ?? '';

        Map<String, dynamic> jsonPayload = {
          "uid": cardId,
          "nama": name,
          "nim": nim,
          "divisi": divisi,
        };

        BluetoothDevice? device = bleService.connectedDevice;
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

          setState(() {
            isIdCardDetected = false;
            isLoadingToRegister = false;
          });
          return;
        }

        String encodeData = jsonEncode(jsonPayload);
        bleService.sendBluetoothData(device, encodeData);

        Timer? checkTimer;
        final completer = Completer<bool>();

        final timeoutTimer = Timer(const Duration(minutes: 1), () {
          if (!completer.isCompleted) {
            checkTimer?.cancel();
            completer.completeError(TimeoutException("Request timeout"));
          }
        });

        checkTimer = Timer.periodic(const Duration(milliseconds: 500), (checkTimer) {
          if (registerStatus == RegisterStatus.success) {
            checkTimer.cancel();
            timeoutTimer.cancel();

            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } else if (registerStatus == RegisterStatus.failed) {
            checkTimer.cancel();
            timeoutTimer.cancel();

            if (!completer.isCompleted) {
              completer.complete(false);
            }
          } else if (registerStatus == RegisterStatus.timeout) {
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

          Toastification().show(
            title: const Text("Member Register"),
            description: Text(callbackMsg),
            type: notificationType,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );

          if (isSuccess) ref.invalidate(membersProvider);
        } on TimeoutException {
          Toastification().show(
            title: const Text("Member Register"),
            description: const Text("Request timeout. Please try again."),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        } finally {
          memberIdCardController.clear();
          memberNameController.clear();
          memberNIMController.clear();

          setState(() {
            callbackMsg = "";
            selectedDivision = null;
            isIdCardDetected = false;
            isLoadingToRegister = false;
            registerStatus = RegisterStatus.none;
          });
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
                        const FaIcon(FontAwesomeIcons.userPlus, size: 36.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            "Register New Member",
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
                      "There no Member ID Card detected. Please tap the Member ID Card to RFID sensor to detect it in here.",
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
            Text("Add New Member", style: Theme.of(context).textTheme.titleLarge),
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
                    readOnly: true,
                    controller: memberIdCardController,
                    decoration: const InputDecoration(
                      labelText: "Member Card ID",
                      icon: FaIcon(FontAwesomeIcons.idBadge, size: 24.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
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

                        if (memberData.isNotEmpty) {
                          if (kDebugMode) {
                            debugPrint("Found: $memberData");
                          }

                          setState(() {
                            memberNameController.text = memberData[1];
                            selectedDivision = Divisions.values.firstWhere(
                              (element) => element.aliases == memberData[0],
                            );
                          });
                        }
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
                  DropdownButtonFormField<Divisions>(
                    initialValue: selectedDivision,
                    decoration: InputDecoration(
                      labelText: "Member Division",
                      hintText: LocaleKeys.member_page_dialog_field_division.tr(context: context),
                      icon: const FaIcon(FontAwesomeIcons.sitemap, size: 24.0),
                    ),
                    items: Divisions.values.map((item) {
                      return DropdownMenuItem<Divisions>(value: item, child: Text(item.aliases));
                    }).toList(),
                    onChanged: (Divisions? value) {
                      if (value == selectedDivision) return;
                      setState(() => selectedDivision = value);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => validateFormInput(),
                    child: isLoadingToRegister
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
                        : Text("Register Member", style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    membersData = MembersData();
    bleService = BleService();

    membersData
        .loadData()
        .then((success) {
          if (success) {
            if (kDebugMode) {
              debugPrint("FOSTI members data excel loaded successfully.");
            }
          } else {
            if (kDebugMode) {
              debugPrint("No FOSTI members data excel found or failed to load.");
            }
          }
        })
        .catchError((e, trace) {
          if (kDebugMode) {
            debugPrintStack(
              stackTrace: trace,
              label: "Error loading FOSTI members data excel",
              maxFrames: 5,
            );
          }
        });

    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, '1');
    }
  }

  @override
  void dispose() {
    BluetoothDevice? device = bleService.connectedDevice;
    if (device != null) {
      bleService.sendBluetoothData(device, 'cancel');

      if (isIdCardDetected) {
        bleService.sendBluetoothData(device, 'cancel');
      }
    }

    memberIdCardController.dispose();
    memberNameController.dispose();
    memberNIMController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamListener<String>(
      stream: bleService.dataStream,
      onData: (context, receivedData) {
        Map<String, dynamic> decodedData = {};
        Map<String, dynamic> data = {};

        if (kDebugMode) {
          debugPrint("Received data: $receivedData");
        }

        try {
          decodedData = jsonDecode(receivedData);
          data = decodedData['data'];
        } catch (_, trace) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: trace, label: "Error decoding received data", maxFrames: 5);
          }
        }

        callbackMsg = decodedData['message'];
        if (decodedData['status'] == "CARD_DETECTED") {
          setState(() => isIdCardDetected = true);
          memberIdCardController.text = data['cardId'];
        } else if (decodedData['status'] == "REGISTER_CARD_SUCCESS") {
          registerStatus = RegisterStatus.success;
        } else if (decodedData['status'] == "REGISTER_CARD_FAILED") {
          registerStatus = RegisterStatus.failed;
        } else if (decodedData['status'] == "TIMEOUT_NO_DATA") {
          registerStatus = RegisterStatus.timeout;

          if (!isLoadingToRegister) {
            Toastification().show(
              title: const Text("Member Register"),
              description: const Text("Request timeout. Please try again."),
              type: ToastificationType.error,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );

            memberIdCardController.clear();
            memberNameController.clear();
            memberNIMController.clear();

            setState(() {
              callbackMsg = "";
              selectedDivision = null;
              isIdCardDetected = false;
              registerStatus = RegisterStatus.none;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(LocaleKeys.control_panel_page_title_register.tr(context: context)),
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
            return state == BleConnectionState.connected
                ? isIdCardDetected
                      ? cardDetected()
                      : noCardDetected()
                : noBTConnected();
          },
        ),
      ),
    );
  }
}
