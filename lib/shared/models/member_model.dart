import 'dart:core';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_model.freezed.dart';
part 'member_model.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum Divisions {
  ristek("Riset dan Teknologi", "RISTEK"),
  keor("Keorganisasian", "KEOR"),
  hubpub("Hubungan Publik", "HUBPUB"),
  bphi("Badan Pengurus Harian dan Inti", "BPHI");

  final String name;
  final String aliases;

  Divisions(this.name, this.aliases);
}

@freezed
abstract class MemberModel with _$MemberModel {
  const MemberModel._();

  const factory MemberModel({
    @JsonKey(name: 'id') required String memberId,
    @JsonKey(name: 'kartu', fromJson: _cardIdFromJson, toJson: _cardIdToJson)
    required String cardId,
    @JsonKey(name: 'nama') required String name,
    required String nim,
    @JsonKey(name: 'divisi') required Divisions division,
    required DateTime createdAt,
  }) = _MemberModel;

  factory MemberModel.fromJson(Map<String, dynamic> json) => _$MemberModelFromJson(json);
}

String _cardIdFromJson(Map<String, dynamic> cardJson) => cardJson['uid'] as String;

Map<String, dynamic> _cardIdToJson(String cardId) => {'uid': cardId};
