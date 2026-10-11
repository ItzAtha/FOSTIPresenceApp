import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/features/dashboard/widgets/scaled_switch_list_tile.dart';
import 'package:attendance_management/shared/service/preferences_service.dart';
import 'package:attendance_management/translations/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/language.dart';
import '../../../core/app_constants.dart';
import '../../../core/utils/debouncer.dart';
import 'app_about_dialog.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with SingleTickerProviderStateMixin {
  bool isThemeOptionOpened = false;
  bool isLanguageOptionOpened = false;

  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  late Language selectedLanguage;

  late final Animation<double> btMaxRetriesAnimation;
  late final AnimationController btMaxRetriesAnimController;

  static const List<MapEntry<int, String>> btRetryOptions = [
    MapEntry(1, '1 attempt'),
    MapEntry(3, '3 attempts'),
    MapEntry(5, '5 attempts'),
    MapEntry(10, '10 attempts'),
    MapEntry(15, '15 attempts'),
    MapEntry(-1, 'Unlimited'),
  ];

  @override
  void initState() {
    super.initState();

    btMaxRetriesAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    btMaxRetriesAnimation = CurvedAnimation(
      parent: btMaxRetriesAnimController,
      curve: Curves.easeInOutCubic,
    );

    if (PreferencesService.instance.btAutoReconnectNotifier.value) {
      btMaxRetriesAnimController.forward();
    } else {
      btMaxRetriesAnimController.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      selectedLanguage = Language.allLanguages.firstWhere(
        (lang) => lang.code == context.locale.languageCode,
      );
    });
  }

  @override
  void dispose() {
    btMaxRetriesAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = AdaptiveTheme.of(context).mode;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: ListView(
          children: <Widget>[
            Text(
              "General",
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(color: Colors.grey, thickness: 1.5),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
              valueListenable: PreferencesService.instance.btAutoReconnectNotifier,
              builder: (context, isEnable, _) {
                return ScaledSwitchListTile(
                  value: isEnable,
                  title: Text(
                    LocaleKeys.setting_page_general_app_auto_reconnect_bt_title.tr(
                      context: context,
                    ),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    LocaleKeys.setting_page_general_app_auto_reconnect_bt_description.tr(
                      context: context,
                    ),
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  leading: const FaIcon(FontAwesomeIcons.bluetooth),
                  scale: 0.85,
                  onChanged: (value) async {
                    PreferencesService.instance.setBTAutoReconnect(value);

                    if (value) {
                      btMaxRetriesAnimController.forward();
                    } else {
                      btMaxRetriesAnimController.reverse();
                    }
                  },
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: PreferencesService.instance.btReconnectRetriesNotifier,
              builder: (context, maxRetries, _) {
                return ClipRect(
                  child: SizeTransition(
                    sizeFactor: btMaxRetriesAnimation,
                    alignment: Alignment.bottomCenter,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -1.0),
                        end: Offset.zero,
                      ).animate(btMaxRetriesAnimation),
                      child: FadeTransition(
                        opacity: btMaxRetriesAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSizes.p12),
                          child: ListTile(
                            leading: const FaIcon(FontAwesomeIcons.rotate, size: 22.0),
                            title: Text(
                              "Max Retries",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "Number of bluetooth reconnection attempts",
                              textAlign: TextAlign.justify,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing: DropdownMenu<int>(
                              initialSelection: maxRetries,
                              width: 120.0,
                              menuHeight: 160.0,
                              requestFocusOnTap: false,
                              inputDecorationTheme: const InputDecorationTheme(
                                isDense: true,
                                contentPadding: EdgeInsets.all(AppSizes.p8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                ),
                              ),
                              menuStyle: MenuStyle(
                                elevation: const WidgetStatePropertyAll(4.0),
                                backgroundColor: WidgetStatePropertyAll(
                                  Theme.of(context).cardTheme.color,
                                ),
                              ),
                              onSelected: (int? value) {
                                if (value != null) {
                                  PreferencesService.instance.setBTMaxRetries(value);
                                }
                              },
                              dropdownMenuEntries: btRetryOptions.map((entry) {
                                return DropdownMenuEntry<int>(value: entry.key, label: entry.value);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            ExpansionTile(
              title: Text(
                "Theme",
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: FaIcon(
                FontAwesomeIcons.circleHalfStroke,
                color: Theme.of(context).iconTheme.color,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(currentTheme.modeName, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(width: 16.0),
                  AnimatedRotation(
                    turns: isThemeOptionOpened ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 20.0,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
              expansionAnimationStyle: const AnimationStyle(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 500),
              ),
              onExpansionChanged: (isExpanded) {
                setState(() => isThemeOptionOpened = isExpanded);
              },
              children: <Widget>[
                RadioGroup(
                  groupValue: currentTheme,
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        AdaptiveTheme.of(context).setThemeMode(value);
                      }
                    });
                  },
                  child: Column(
                    children: <Widget>[
                      for (final theme in AdaptiveThemeMode.values)
                        RadioListTile(title: Text(theme.name), value: theme),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(
                LocaleKeys.setting_page_general_app_language_title.tr(context: context),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: FaIcon(FontAwesomeIcons.language, color: Theme.of(context).iconTheme.color),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(selectedLanguage.name, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(width: 16.0),
                  AnimatedRotation(
                    turns: isLanguageOptionOpened ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 20.0,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
              expansionAnimationStyle: const AnimationStyle(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 500),
              ),
              onExpansionChanged: (isExpanded) {
                setState(() => isLanguageOptionOpened = isExpanded);
              },
              children: <Widget>[
                RadioGroup(
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                      context.setLocale(Locale(selectedLanguage.code));
                    });
                  },
                  child: Column(
                    children: <Widget>[
                      for (final lang in Language.allLanguages)
                        RadioListTile(title: Text(lang.name), value: lang),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              "Notifications",
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(color: Colors.grey, thickness: 1.5),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
              valueListenable: PreferencesService.instance.simExpiredNotifyNotifier,
              builder: (context, isEnable, _) {
                return ScaledSwitchListTile(
                  value: isEnable,
                  title: Text(
                    "Notify SIM Expired",
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    "Notify when SIM Internet has been expired and must be renewed immediately before the SIM number expires",
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  leading: const FaIcon(FontAwesomeIcons.simCard),
                  scale: 0.85,
                  onChanged: (value) async {
                    PreferencesService.instance.setSIMExpiredNotify(value);
                  },
                );
              },
            ),
            const SizedBox(height: 24.0),
            Text(
              "Support & About",
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(color: Colors.grey, thickness: 1.5),
            const SizedBox(height: 8.0),
            ListTile(
              title: Text(
                "FAQ",
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: const FaIcon(FontAwesomeIcons.circleQuestion),
              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 20.0),
              onTap: () {
                Toastification().show(
                  title: Text(LocaleKeys.alert_notify_coming_soon_title.tr(context: context)),
                  description: Text(
                    LocaleKeys.alert_notify_coming_soon_description.tr(context: context),
                  ),
                  type: ToastificationType.info,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );
              },
            ),
            ListTile(
              title: Text(
                "Privacy Policy",
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: const FaIcon(FontAwesomeIcons.shieldHalved),
              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 20.0),
              onTap: () => context.pushNamed(AppRoutes.privacyPolicyRoute.name),
            ),
            ListTile(
              title: Text(
                "Terms of Service",
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: const FaIcon(FontAwesomeIcons.fileContract),
              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 20.0),
              onTap: () => context.pushNamed(AppRoutes.termsOfServiceRoute.name),
            ),
            ListTile(
              title: Text(
                LocaleKeys.setting_page_more_info_about_app_title.tr(context: context),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              leading: const FaIcon(FontAwesomeIcons.circleInfo),
              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 20.0),
              onTap: () async {
                final PackageInfo info = await PackageInfo.fromPlatform();
                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (context) => AppAboutDialog(
                    applicationIcon: Image.asset("assets/app-icon.png", scale: 12.0),
                    applicationName: info.appName,
                    applicationVersion: 'v${info.version} (Build ${info.buildNumber})',
                    applicationLegalese: '\u{a9} 2026 Atha - FOSTI UMS',
                    children: <Widget>[
                      Text(
                        LocaleKeys.setting_page_more_info_about_app_dialog.tr(context: context),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
