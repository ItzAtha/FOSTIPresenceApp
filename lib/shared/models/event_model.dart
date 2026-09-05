import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
abstract class EventModel with _$EventModel {
  const EventModel._();

  const factory EventModel({
    @JsonKey(name: 'id') required String eventId,
    @JsonKey(name: 'judul') required String title,
    @JsonKey(name: 'deskripsi') required String description,
    @JsonKey(name: 'lokasi') required String location,
    @JsonKey(name: 'tanggal') required DateTime eventDate,
    @Default(false) bool isActive,
    required DateTime createdAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
