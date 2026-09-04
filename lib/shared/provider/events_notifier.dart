import 'package:attendance_management/shared/models/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../manager/database_manager.dart';

part 'events_notifier.g.dart';

@riverpod
class EventsNotifier extends _$EventsNotifier {
  @override
  Future<List<EventModel>> build() async {
    return await _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents() async {
    DatabaseManager manager = DatabaseManager();
    List<EventModel> events = [];

    Map<String, dynamic> responseJson = await manager.readData(endpoint: 'api/event');
    if (responseJson.isNotEmpty) {
      List<dynamic> eventsList = responseJson['data'] as List<dynamic>;
      for (final eventData in eventsList) {
        EventModel event = EventModel.fromJson(eventData);
        events.add(event);
        print(event.toJson());
      }
    }
    return events;
  }

  void updateEvent(EventModel updatedEvent) {
    final currentEvents = state.value;

    if (currentEvents == null) return;
    state = AsyncData([
      for (final event in currentEvents)
        if (event.eventId == updatedEvent.eventId) updatedEvent else event,
    ]);
  }
}
