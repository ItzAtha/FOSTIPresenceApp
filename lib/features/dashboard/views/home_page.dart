import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/shared/models/event_model.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:attendance_management/shared/provider/members_notifier.dart';
import 'package:attendance_management/translations/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_constants.dart';
import '../../../shared/provider/events_notifier.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(LocaleKeys.app_title.tr(context: context)),
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
                          LocaleKeys.home_page_stats_title_active_event.tr(context: context),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 150.0),
                    padding: const EdgeInsets.all(AppSizes.p16),
                    child: Center(
                      child: eventsAsync.when(
                        data: (events) {
                          if (events.isEmpty) {
                            return Text(
                              LocaleKeys.home_page_no_active_event.tr(context: context),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            );
                          }

                          EventModel activeEvent = events.where((event) => event.isActive).first;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                activeEvent.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy, HH:mm',
                                ).format(DateTime.parse(activeEvent.eventDate.toIso8601String())),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(thickness: 1.5),
                              const SizedBox(height: 8.0),
                              Text(
                                activeEvent.description,
                                style: Theme.of(context).textTheme.labelMedium,
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          );
                        },
                        loading: () => ValueListenableBuilder(
                          valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                          builder: (_, mode, child) {
                            return CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                mode == AdaptiveThemeMode.light
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                        error: (error, stackTrace) => Text(
                          LocaleKeys.home_page_no_active_event.tr(context: context),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
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
                                  LocaleKeys.home_page_stats_title_total_members.tr(
                                    context: context,
                                  ),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: membersAsync.when(
                                data: (members) {
                                  int currentYear = DateTime.now().year;
                                  List<int> generation = List.generate(
                                    2,
                                    (index) => currentYear - 2 + index,
                                  );

                                  List<MemberModel> totalMembers = members.where((member) {
                                    String currentGeneration = "20${member.nim.substring(4, 6)}";
                                    return generation.contains(
                                      int.tryParse(currentGeneration) ?? 0,
                                    );
                                  }).toList();

                                  return Text(
                                    totalMembers.length.toString(),
                                    style: Theme.of(context).textTheme.displaySmall
                                        ?.copyWith(fontSize: 48.0),
                                  );
                                },
                                loading: () => ValueListenableBuilder(
                                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                                  builder: (_, mode, child) {
                                    return CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        mode == AdaptiveThemeMode.light
                                            ? AppColors.primary
                                            : AppColors.primary.withValues(alpha: 0.6),
                                      ),
                                    );
                                  },
                                ),
                                error: (error, stackTrace) => Text(
                                  "0",
                                  style: Theme.of(context).textTheme.displaySmall
                                      ?.copyWith(fontSize: 48.0),
                                ),
                              ),
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
                                  LocaleKeys.home_page_stats_title_total_events.tr(
                                    context: context,
                                  ),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: eventsAsync.when(
                                data: (events) => Text(
                                  events.length.toString(),
                                  style: Theme.of(context).textTheme.displaySmall
                                      ?.copyWith(fontSize: 48.0),
                                ),
                                loading: () => ValueListenableBuilder(
                                  valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                                  builder: (_, mode, child) {
                                    return CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        mode == AdaptiveThemeMode.light
                                            ? AppColors.primary
                                            : AppColors.primary.withValues(alpha: 0.6),
                                      ),
                                    );
                                  },
                                ),
                                error: (error, stackTrace) => Text(
                                  "0",
                                  style: Theme.of(context).textTheme.displaySmall
                                      ?.copyWith(fontSize: 48.0),
                                ),
                              ),
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
