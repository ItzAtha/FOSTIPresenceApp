import 'package:attendance_management/shared/models/event_log_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../manager/database_manager.dart';

part 'events_logs_notifier.g.dart';

@riverpod
class EventsLogsNotifier extends _$EventsLogsNotifier {
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  Future<Map<String, List<EventLogModel>>> build() async {
    return await _fetchEventsLogs();
  }

  Future<Map<String, List<EventLogModel>>> _fetchEventsLogs() async {
    Map<String, List<EventLogModel>> eventsLogs = {};

    Map<String, dynamic> responseJson = await _dbManager.readData(endpoint: 'api/event');
    if (responseJson.isNotEmpty) {
      List<dynamic> eventsList = responseJson['data'] as List<dynamic>;
      for (final eventData in eventsList) {
        List<EventLogModel> eventLogsList = [];
        String eventId = eventData['id'];

        List<dynamic> eventLogs = eventData['logs'] as List<dynamic>;
        for (final logData in eventLogs) {
          Map<String, dynamic> logJson = logData['log'] as Map<String, dynamic>;
          String cardId = logJson['uid_kartu'];
          Roles role = Roles.values.firstWhere((r) => r.name == logJson['role']);
          DateTime loginDate = DateTime.parse(logJson['tanggal_masuk']);
          DateTime logoutDate = DateTime.parse(logJson['tanggal_keluar']);
          Information information = Information.values.firstWhere(
            (i) => i.name == logJson['keterangan'],
          );

          EventLogModel logModel = EventLogModel(
            eventId: eventId,
            cardId: cardId,
            role: role,
            loginDate: loginDate,
            logoutDate: logoutDate,
            information: information,
          );
          eventLogsList.add(logModel);
        }
        eventsLogs[eventId] = eventLogsList;
      }
    }
    return eventsLogs;
  }

  Future<List<EventLogModel>> getEventLogs(String eventId) async {
    final logs = await future;
    return logs[eventId] ?? [];
  }
}
