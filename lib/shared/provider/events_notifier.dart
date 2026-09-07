import 'package:attendance_management/shared/models/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../manager/database_manager.dart';

part 'events_notifier.g.dart';

@riverpod
class EventsNotifier extends _$EventsNotifier {
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  Future<List<EventModel>> build() async {
    return await _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents() async {
    List<EventModel> events = [];

    Map<String, dynamic> responseJson = await _dbManager.readData(endpoint: 'api/event');
    if (responseJson.isNotEmpty) {
      List<dynamic> eventsList = responseJson['data'] as List<dynamic>;
      for (final eventData in eventsList) {
        EventModel event = EventModel.fromJson(eventData);
        events.add(event);
      }
    }
    return events;
  }

  Future<bool> updateEvent(EventModel updatedEvent) async {
    final currentEvents = state.value;
    bool isUpdateSuccess = false;

    if (currentEvents == null) return isUpdateSuccess;

    Map<String, dynamic> payload = updatedEvent.toJson();
    payload.remove('id');
    payload.remove('isActive');
    payload.remove('createdAt');

    isUpdateSuccess = await _dbManager.updateData(
      endpoint: 'api/event',
      dataId: updatedEvent.eventId,
      jsonData: payload,
    );

    if (isUpdateSuccess) {
      state = AsyncData([
        for (final event in currentEvents)
          if (event.eventId == updatedEvent.eventId) updatedEvent else event,
      ]);
    }

    return isUpdateSuccess;
  }

  Future<bool> deleteEvent(EventModel deletedEvent) async {
    final currentEvents = state.value;
    bool isUpdateSuccess = false;

    if (currentEvents == null) return isUpdateSuccess;

    isUpdateSuccess = await _dbManager.deleteData(
      endpoint: 'api/event',
      dataId: deletedEvent.eventId,
    );

    if (isUpdateSuccess) {
      state = AsyncData([
        for (final event in currentEvents)
          if (event.eventId != deletedEvent.eventId) event,
      ]);
    }

    return isUpdateSuccess;
  }
}
