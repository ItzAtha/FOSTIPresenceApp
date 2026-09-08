import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/manager/database_manager.dart';
import 'package:attendance_management/shared/provider/members_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/members_data_factory.dart';
import '../../../../manager/bluetooth_manager.dart';
import '../../../../translations/locale_keys.g.dart';
import '../../../core/app_constants.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/member_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool isIdCardDetected = false;
  bool isLoadingToRegister = false;

  Divisions? selectedDivision;
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  late MembersData membersData;
  late BluetoothManager bluetoothManager;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController memberCardIdController = TextEditingController();
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberNIMController = TextEditingController();

  @override
  void initState() {
    super.initState();
    membersData = MembersData();
    bluetoothManager = BluetoothManager(context: context);

    membersData
        .loadData()
        .then((isSuccess) {
          if (!mounted) return;

          BluetoothDevice? device = BluetoothManager.getConnectedDevice;
          if (device != null) {
            bluetoothManager.sendBluetoothData(device, '1');
          }
        })
        .catchError((error) {
          print("Error loading FOSTI members data excel: $error");
        });
  }

  Future<void> validateFormInput() async {
    FormState? form = formKey.currentState;

    if (form != null) {
      if (form.validate()) {
        setState(() => isLoadingToRegister = true);

        String cardId = memberCardIdController.text.trim();
        String name = memberNameController.text.trim();
        String nim = memberNIMController.text.trim();
        String divisi = selectedDivision?.name ?? '';

        Map<String, dynamic> jsonPayload = {
          "uid": cardId,
          "nama": name,
          "nim": nim,
          "divisi": divisi,
        };

        DatabaseManager dbManager = DatabaseManager();
        bool isSuccess = await dbManager.createData(
          endpoint: 'api/mahasiswa',
          jsonData: jsonPayload,
        );

        if (isSuccess) {
          Toastification().show(
            title: const Text("Member Register"),
            description: Text("Successfully register new member with ID: $cardId"),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );

          print("Member registered successfully.");
          ref.invalidate(membersProvider);
          memberCardIdController.clear();
          memberNameController.clear();
          memberNIMController.clear();
          setState(() => selectedDivision = null);
        } else {
          Toastification().show(
            title: const Text("Member Register"),
            description: Text(
              "Failed to register member. Data already exists in database with ID: $cardId",
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }
        setState(() => isLoadingToRegister = false);
      }
    }
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
    memberCardIdController.text = "B3 3D F3 2A";

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
                border: Border.all(color: Colors.blue, width: 3.0),
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
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8.0),
                  TextFormField(
                    readOnly: true,
                    controller: memberCardIdController,
                    decoration: const InputDecoration(
                      labelText: "Member Card ID",
                      icon: FaIcon(FontAwesomeIcons.idBadge, size: 24.0),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: memberNameController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.member_page_dialog_field_name.tr(context: context),
                      hintText: "Andi Setya Budi",
                      icon: const FaIcon(FontAwesomeIcons.user, size: 24.0),
                      border: const OutlineInputBorder(),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      isDense: true,
                      labelText: LocaleKeys.member_page_dialog_field_nim.tr(context: context),
                      hintText: "L200250001",
                      icon: const FaIcon(FontAwesomeIcons.idCard, size: 24.0),
                      border: const OutlineInputBorder(),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (value) async {
                      debouncer.run(() {
                        final memberData = membersData.findStudentByNIM(value);
                        print("Found: $memberData");

                        if (memberData.isEmpty) {
                          memberNameController.text = "";
                          setState(() => selectedDivision = null);
                          return;
                        }

                        setState(() {
                          memberNameController.text = memberData[1];
                          selectedDivision = Divisions.values.firstWhere(
                            (element) => element.aliases == memberData[0],
                          );
                        });
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
                  Row(
                    children: <Widget>[
                      const FaIcon(FontAwesomeIcons.sitemap, size: 24.0),
                      const SizedBox(width: 16.0),
                      DropdownButton<Divisions>(
                        value: selectedDivision,
                        hint: Text(
                          LocaleKeys.member_page_dialog_field_division.tr(context: context),
                        ),
                        items: Divisions.values.map((item) {
                          return DropdownMenuItem<Divisions>(
                            value: item,
                            child: Text(item.aliases),
                          );
                        }).toList(),
                        onChanged: (Divisions? value) {
                          if (value == selectedDivision) return;
                          setState(() => selectedDivision = value);
                        },
                      ),
                    ],
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
  void dispose() {
    super.dispose();

    BluetoothDevice? device = BluetoothManager.getConnectedDevice;
    if (device != null) {
      bluetoothManager.sendBluetoothData(device, 'cancel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: isIdCardDetected ? cardDetected() : noCardDetected(),
    );
  }
}
