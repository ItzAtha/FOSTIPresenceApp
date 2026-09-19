import 'dart:core';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_log_model.freezed.dart';
part 'event_log_model.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum Roles {
  participant("PESERTA"),
  committe("PANITIA"),
  bphi("BPHI");

  final String name;

  Roles(this.name);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum Information {
  present("HADIR"),
  permission("IZIN"),
  absent("ALPA");

  final String name;

  Information(this.name);
}

@freezed
abstract class EventLogModel with _$EventLogModel {
  const EventLogModel._();

  const factory EventLogModel({
    required String eventId,
    required String cardId,
    Roles? role,
    DateTime? loginDate,
    DateTime? logoutDate,
    required Information information,
  }) = _EventLogModel;

  factory EventLogModel.fromJson(Map<String, dynamic> json) => _$EventLogModelFromJson(json);
}
