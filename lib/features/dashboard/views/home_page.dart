import 'dart:async';

import 'package:attendance_management/manager/bluetooth_manager.dart';
// import 'package:attendance_management/manager/events_manager.dart';
import 'package:attendance_management/manager/wifi_manager.dart';
import 'package:attendance_management/translations/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/utils/connectivity_utils.dart';
import '../../../../manager/database_manager.dart';

enum Answer { YES, NO }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final activeEvent = true;
  final eventsData = [];

  Timer? wifiCheckerTask;
  Timer? espStatusChecker;
  bool isInternetConnected = false;

  late bool isLoadingDone;
  late bool isWiFiConnect;
  late bool isDeviceConnect;

  late DatabaseManager database;

  Future<void> fetchAllEvents({required String path}) async {
    setState(() => isLoadingDone = false);

    if (!await ConnectivityUtils.checkConnection()) {
      if (!mounted) return;

      Toastification().show(
        context: context,
        title: Text(LocaleKeys.alert_notify_internet_title.tr(context: context)),
        description: Text(LocaleKeys.alert_notify_internet_description.tr(context: context)),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: Duration(seconds: 2),
        animationDuration: Duration(milliseconds: 500),
      );

      setState(() => isLoadingDone = true);
      return;
    }

    dynamic rawData = await database.readData(endpoint: path);
    if (!mounted) return;

    if (rawData != null) {
      // eventsData = rawData as List<Event>;
      if (eventsData.isNotEmpty) {
        // setState(
        //   () => activeEvent = eventsData.where((event) => event.isActive == true).firstOrNull,
        // );

        if (activeEvent == null) {
          Toastification().show(
            context: context,
            title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
            description: Text(
              LocaleKeys.alert_notify_event_description_no_active.tr(context: context),
            ),
            type: ToastificationType.info,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: Duration(seconds: 2),
            animationDuration: Duration(milliseconds: 500),
          );
        }

        isInternetConnected = true;
      } else {
        Toastification().show(
          context: context,
          title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
          description: Text(LocaleKeys.alert_notify_event_description_no_data.tr(context: context)),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: Duration(seconds: 2),
          animationDuration: Duration(milliseconds: 500),
        );
      }
    } else {
      Toastification().show(
        context: context,
        title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
        description: Text(LocaleKeys.alert_notify_event_description_not_load.tr(context: context)),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: Duration(seconds: 2),
        animationDuration: Duration(milliseconds: 500),
      );
    }

    setState(() => isLoadingDone = true);
  }

  void startWiFiChecker() {
    wifiCheckerTask = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!await ConnectivityUtils.checkConnection() && isInternetConnected) {
        setState(() => isInternetConnected = false);

        if (!mounted) return;
        Toastification().show(
          context: context,
          title: Text(LocaleKeys.alert_notify_internet_title.tr(context: context)),
          description: Text(LocaleKeys.alert_notify_internet_description.tr(context: context)),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: Duration(seconds: 2),
          animationDuration: Duration(milliseconds: 500),
        );
      }

      if (await ConnectivityUtils.checkConnection() && !isInternetConnected) {
        setState(() => isInternetConnected = true);
      }
    });
  }

  void cancelWiFiChecker() {
    if (wifiCheckerTask!.isActive) {
      wifiCheckerTask?.cancel();
    }
  }

  Future<bool> openWiFiDialog() async {
    bool showPassword = false;
    bool isConnecting = false;
    TextEditingController ssidController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    var wifiDialog = StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text("ESP32 WiFi Setup", textAlign: TextAlign.center),
          scrollable: true,
          contentPadding: EdgeInsets.all(24.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Please connect to the ESP32 WiFi network first to access the control panel.",
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: "WiFi SSID",
                  hintText: "e.g. ESP32-Access-Point",
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "WiFi Password",
                  suffixIcon: InkWell(
                    customBorder: CircleBorder(),
                    onTap: () => setDialogState(() => showPassword = !showPassword),
                    child: showPassword
                        ? Icon(Icons.visibility)
                        : Icon(Icons.visibility_off, color: Colors.grey),
                  ),
                ),
                obscureText: !showPassword,
                enableSuggestions: false,
              ),
              isConnecting
                  ? Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Text("Connecting to ESP32 WiFi"),
                          SizedBox(width: 8.0),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.green.shade300
                                    : Colors.green.shade200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: !isConnecting
                  ? () async {
                      setDialogState(() => isConnecting = true);
                      FocusScope.of(context).unfocus();

                      WiFiManager wifiManager = WiFiManager(context: context);
                      bool isSuccess = await wifiManager.connectToWiFi(
                        ssidController.text.trim(),
                        passwordController.text.trim(),
                      );

                      if (!context.mounted) return;

                      if (!isSuccess) {
                        setDialogState(() => isConnecting = false);
                        Toastification().show(
                          context: context,
                          title: Text(LocaleKeys.alert_notify_wifi_title.tr(context: context)),
                          description: Text(
                            "Failed to connect to ESP32 WiFi. Please check your credentials and try again.",
                          ),
                          type: ToastificationType.error,
                          style: ToastificationStyle.flat,
                          alignment: Alignment.bottomCenter,
                          autoCloseDuration: Duration(seconds: 2),
                          animationDuration: Duration(milliseconds: 500),
                        );
                        return;
                      }

                      Navigator.of(context).pop(Answer.YES);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Connect", style: TextStyle(color: Colors.black)),
            ),
            SizedBox(width: 4.0),
            ElevatedButton(
              onPressed: !isConnecting
                  ? () {
                      Navigator.of(context).pop();
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: Text(
                LocaleKeys.event_page_dialog_button_cancel.tr(context: context),
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    var isDialogComplete = await showDialog(
      context: context,
      barrierDismissible: false,
      animationStyle: AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (BuildContext context) {
        return wifiDialog;
      },
    );

    return isDialogComplete == Answer.YES;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    database = DatabaseManager();
    fetchAllEvents(path: 'api/event');

    setState(() {
      isWiFiConnect = WiFiManager.isESPWiFiConnected;
      isDeviceConnect = BluetoothManager.isBluetoothConnected;
    });

    startWiFiChecker();
    espStatusChecker = Timer.periodic(1.seconds, (timer) {
      setState(() {
        isWiFiConnect = WiFiManager.isESPWiFiConnected;
        isDeviceConnect = BluetoothManager.isBluetoothConnected;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);

    wifiCheckerTask?.cancel();
    espStatusChecker?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      cancelWiFiChecker();
    } else if (state == AppLifecycleState.resumed) {
      startWiFiChecker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(LocaleKeys.app_title).tr(context: context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: <Widget>[
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 50.0,
                    color: AppColors.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const FaIcon(FontAwesomeIcons.calendarCheck, color: Colors.white),
                        const SizedBox(width: 8.0),
                        Text(
                          LocaleKeys.home_page_stats_title_active_event,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ).tr(context: context),
                      ],
                    ),
                  ),
                  // Container(
                  //   height: 150.0,
                  //   padding: const EdgeInsets.all(16.0),
                  //   child: Center(
                  //     child: isLoadingDone
                  //         ? activeEvent != null
                  //         ? Column(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: <Widget>[
                  //         Text(
                  //           activeEvent!.name,
                  //           style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  //           textAlign: TextAlign.center,
                  //         ),
                  //         Text(
                  //           DateFormat(
                  //             'dd MMMM yyyy, HH:mm',
                  //           ).format(DateTime.parse(activeEvent!ntDate)),
                  //           style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
                  //         ),
                  //         Text(
                  //           activeEvent,
                  //           style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
                  //           textAlign: TextAlign.center,
                  //         ),
                  //       ],
                  //     )
                  //         : Text(
                  //       LocaleKeys.home_page_no_active_event,
                  //       style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
                  //       textAlign: TextAlign.center,
                  //     ).tr(context: context)
                  //         : const CircularProgressIndicator(),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 180.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 50.0,
                            color: AppColors.primary,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const FaIcon(
                                  FontAwesomeIcons.users,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  LocaleKeys.home_page_stats_title_total_members,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white),
                                ).tr(context: context),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: isLoadingDone
                                  ? Text(
                                      eventsData.length.toString(),
                                      style: Theme.of(context).textTheme.displaySmall
                                          ?.copyWith(fontSize: 48.0),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 50.0,
                            color: AppColors.primary,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const FaIcon(
                                  FontAwesomeIcons.calendarDays,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  LocaleKeys.home_page_stats_title_total_events,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white),
                                ).tr(context: context),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: isLoadingDone
                                  ? Text(
                                      eventsData.length.toString(),
                                      style: Theme.of(context).textTheme.displaySmall
                                          ?.copyWith(fontSize: 48.0),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      ),
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
}
