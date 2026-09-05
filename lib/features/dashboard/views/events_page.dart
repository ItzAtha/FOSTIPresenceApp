import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/shared/models/event_model.dart';
import 'package:attendance_management/shared/provider/events_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/connectivity_utils.dart';
import '../../../../translations/locale_keys.g.dart';
import '../../../core/app_constants.dart';
import '../widgets/event_card_widget.dart';

class EventPage extends ConsumerStatefulWidget {
  const EventPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EventPageState();
}

enum Answer { YES, NO }

class _EventPageState extends ConsumerState<EventPage> {
  int currentPage = 1;
  String searchQuery = "";
  static const int maxEventPerPage = 12;

  DateTime? selectedDateTime;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDescController = TextEditingController();
  final TextEditingController eventLocController = TextEditingController();
  final TextEditingController eventDateTimeController = TextEditingController();
  final TextEditingController searchBarController = TextEditingController();

  Future<void> eventEditButton({
    required List<EventModel> eventsData,
    required EventModel eventData,
  }) async {
    EventModel event = eventData;
    String? formattedDate;

    if (!await ConnectivityUtils.checkConnection()) {
      if (!mounted) return;

      Toastification().show(
        title: Text(LocaleKeys.alert_notify_internet_title.tr(context: context)),
        description: Text(LocaleKeys.alert_notify_internet_description.tr(context: context)),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 500),
      );
      return;
    }

    eventNameController.text = event.title;
    eventDescController.text = event.description;
    eventLocController.text = event.location;

    formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.eventDate);
    eventDateTimeController.text = formattedDate;

    if (!mounted) return;

    var eventEditForm = AlertDialog(
      title: Text(
        LocaleKeys.event_page_dialog_edit_title.tr(context: context),
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: formKey,
        canPop: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8.0),
              TextFormField(
                controller: eventNameController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.event_page_dialog_field_name.tr(context: context),
                  hintText: "Event FOSTI 202X",
                  icon: const FaIcon(FontAwesomeIcons.calendar, size: 24.0),
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? value) {
                  if (value.toString().isEmpty) {
                    return LocaleKeys.event_page_dialog_validation_name_required.tr(
                      context: context,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: eventDescController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.event_page_dialog_field_description.tr(context: context),
                  hintText: "FOSTI event held once a year",
                  icon: const FaIcon(FontAwesomeIcons.circleInfo, size: 24.0),
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? value) {
                  if (value.toString().isEmpty) {
                    return LocaleKeys.event_page_dialog_validation_description_required.tr(
                      context: context,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: eventLocController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.event_page_dialog_field_location.tr(context: context),
                  hintText: "Gedung J, Kampus 2, UMS",
                  icon: const FaIcon(FontAwesomeIcons.locationDot, size: 24.0),
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                maxLines: null,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? value) {
                  if (value.toString().isEmpty) {
                    return LocaleKeys.event_page_dialog_validation_location_required.tr(
                      context: context,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: eventDateTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.event_page_dialog_field_date_label.tr(context: context),
                  hintText: LocaleKeys.event_page_dialog_field_date_hint.tr(context: context),
                  icon: const FaIcon(FontAwesomeIcons.calendarDays, size: 24.0),
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );

                  if (pickedDate != null) {
                    if (!mounted) return;

                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );

                    if (pickedTime != null) {
                      DateTime? rawDateTime;
                      int seconds = DateTime.now().second;
                      setState(() {
                        rawDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                          seconds,
                        );
                      });

                      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(rawDateTime!);
                      eventDateTimeController.text = formattedDate;
                    }
                  }
                },
                validator: (String? value) {
                  if (value.toString().isEmpty) {
                    return LocaleKeys.event_page_dialog_validation_date_required.tr(
                      context: context,
                    );
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () => validateFormInput(event),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(
                  LocaleKeys.member_page_dialog_button_update.tr(context: context),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 24.0),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerZone,
                  side: const BorderSide(color: AppColors.dangerZone),
                ),
                child: Text(LocaleKeys.member_page_dialog_button_cancel.tr(context: context)),
              ),
            ),
          ],
        ),
      ],
    );

    showDialog(
      context: context,
      animationStyle: const AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (BuildContext context) {
        return eventEditForm;
      },
    );
  }

  void validateFormInput(EventModel eventData) async {
    FormState? form = formKey.currentState;

    if (form != null) {
      if (form.validate()) {
        if (!await ConnectivityUtils.checkConnection()) {
          if (!mounted) return;

          Toastification().show(
            title: Text(LocaleKeys.alert_notify_internet_title.tr(context: context)),
            description: Text(LocaleKeys.alert_notify_internet_description.tr(context: context)),
            type: ToastificationType.info,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
          return;
        }

        DateTime rawDateTime = DateTime.parse(eventDateTimeController.text);
        DateTime dateTime = DateTime(
          rawDateTime.year,
          rawDateTime.month,
          rawDateTime.day,
          rawDateTime.hour,
          rawDateTime.minute,
          rawDateTime.second,
        );

        if (!mounted) return;
        final updatedEvent = eventData.copyWith(
          title: eventNameController.text,
          description: eventDescController.text,
          eventDate: dateTime,
          location: eventLocController.text,
        );

        bool isSuccess = await ref.read(eventsProvider.notifier).updateEvent(updatedEvent);

        if (!mounted) return;

        if (isSuccess) {
          Toastification().show(
            title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
            description: Text(
              LocaleKeys.alert_notify_event_description_update_success.tr(context: context),
            ),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        } else {
          Toastification().show(
            title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
            description: Text(
              LocaleKeys.alert_notify_event_description_update_failed.tr(context: context),
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }
        context.pop();
      }
    }
  }

  Future<void> eventDeleteButton(EventModel eventData) async {
    if (!await ConnectivityUtils.checkConnection()) {
      if (!mounted) return;

      Toastification().show(
        title: Text(LocaleKeys.alert_notify_internet_title.tr(context: context)),
        description: Text(LocaleKeys.alert_notify_internet_description.tr(context: context)),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 500),
      );
      return;
    }

    if (!mounted) return;

    var eventDeleteConfirm = SimpleDialog(
      title: Text(
        LocaleKeys.event_page_dialog_delete_confirm_title.tr(context: context),
        textAlign: TextAlign.center,
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Column(
            children: <Widget>[
              Text(
                LocaleKeys.event_page_dialog_delete_confirm_description.tr(context: context),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 25.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.pop(Answer.YES),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: Text(
                        LocaleKeys.event_page_dialog_button_yes.tr(context: context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(Answer.NO),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerZone,
                        side: const BorderSide(color: AppColors.dangerZone),
                      ),
                      child: Text(LocaleKeys.event_page_dialog_button_no.tr(context: context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (await showDialog(
          context: context,
          animationStyle: const AnimationStyle(
            curve: Curves.easeIn,
            reverseCurve: Curves.easeOut,
            duration: Duration(milliseconds: 300),
          ),
          builder: (BuildContext context) {
            return eventDeleteConfirm;
          },
        ) ==
        Answer.YES) {
      bool isSuccess = await ref.read(eventsProvider.notifier).deleteEvent(eventData);

      if (!mounted) return;

      if (isSuccess) {
        Toastification().show(
          title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
          description: Text(
            LocaleKeys.alert_notify_event_description_delete_success.tr(context: context),
          ),
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      } else {
        Toastification().show(
          title: Text(LocaleKeys.alert_notify_event_title.tr(context: context)),
          description: Text(
            LocaleKeys.alert_notify_event_description_delete_failed.tr(context: context),
          ),
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  Widget loadingData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ValueListenableBuilder(
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
          const SizedBox(height: 16.0),
          Text(
            LocaleKeys.event_page_loading_data_process.tr(context: context),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget noEvents() {
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
                        const Icon(Icons.event, size: 40.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            LocaleKeys.event_page_loading_data_no_data_title.tr(context: context),
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
                      LocaleKeys.event_page_loading_data_no_data_description.tr(context: context),
                      textAlign: TextAlign.center,
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

  Widget hasEvents(List<EventModel> events) {
    List<EventModel> filteredEvents = events.where((event) {
      return event.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    final totalPages = (filteredEvents.length / maxEventPerPage).ceil();
    if (totalPages > 0 && currentPage > totalPages) {
      currentPage = totalPages;
    }

    final startIndex = (currentPage - 1) * maxEventPerPage;
    final endIndex = (startIndex + maxEventPerPage).clamp(0, filteredEvents.length);
    final currentEvents = filteredEvents.sublist(startIndex, endIndex);

    return Column(
      children: <Widget>[
        Container(
          height: 50.0,
          margin: const EdgeInsets.all(AppSizes.p16),
          child: SearchBar(
            controller: searchBarController,
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchBarController.clear();
                    setState(() => searchQuery = "");
                  },
                ),
            ],
            hintText: LocaleKeys.search_bar_event.tr(context: context),
            textInputAction: TextInputAction.search,
            onChanged: (String value) {
              setState(() {
                searchQuery = value;
                currentPage = 1;
              });
            },
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraint) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSizes.p16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight - (AppSizes.p16 * 2)),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        AnimationLimiter(
                          child: Column(
                            children: List<Widget>.generate(currentEvents.length, (index) {
                              final eventData = currentEvents[index];

                              return Column(
                                children: <Widget>[
                                  AnimationConfiguration.staggeredList(
                                    position: index,
                                    delay: const Duration(milliseconds: 300),
                                    duration: const Duration(milliseconds: 800),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: EventCardWidget(
                                          title: eventData.title,
                                          description: eventData.description,
                                          location: eventData.location,
                                          date: eventData.eventDate,
                                          editButton: () => eventEditButton(
                                            eventsData: events,
                                            eventData: eventData,
                                          ),
                                          deleteButton: () => eventDeleteButton(eventData),
                                          downloadButton: () => (),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (index < currentEvents.length - 1)
                                    const SizedBox(height: 16.0),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            previousPageButton(),
                            const SizedBox(width: 20.0),
                            Text(
                              LocaleKeys.paginating_page_info.tr(
                                context: context,
                                namedArgs: {'current': '$currentPage', 'total': '$totalPages'},
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            nextPageButton(totalPages: totalPages),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget previousPageButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      color: Colors.white,
      style: IconButton.styleFrom(
        minimumSize: const Size(50, 40),
        backgroundColor: currentPage > 1 ? AppColors.primary : Colors.grey,
      ),
      onPressed: currentPage > 1
          ? () {
              setState(() {
                currentPage--;
              });

              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          : null,
    );
  }

  Widget nextPageButton({required int totalPages}) {
    return IconButton(
      icon: const Icon(Icons.arrow_forward_ios),
      color: Colors.white,
      style: IconButton.styleFrom(
        minimumSize: const Size(50, 40),
        backgroundColor: currentPage < totalPages ? AppColors.primary : Colors.grey,
      ),
      onPressed: currentPage < totalPages
          ? () {
              setState(() {
                currentPage++;
              });

              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          : null,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      body: eventsAsync.when(
        loading: () => loadingData(),
        error: (error, stackTrace) => noEvents(),
        data: (events) {
          if (events.isEmpty) {
            return noEvents();
          }

          return hasEvents(events);
        },
      ),
    );
  }
}
