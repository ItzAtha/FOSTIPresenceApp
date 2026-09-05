import 'package:attendance_management/manager/database_manager.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'members_notifier.g.dart';

@riverpod
class MembersNotifier extends _$MembersNotifier {
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  Future<List<MemberModel>> build() async {
    return await _fetchMembers();
  }

  Future<List<MemberModel>> _fetchMembers() async {
    DatabaseManager manager = DatabaseManager();
    List<MemberModel> members = [];

    Map<String, dynamic> responseJson = await manager.readData(endpoint: 'api/mahasiswa');
    if (responseJson.isNotEmpty) {
      List<dynamic> membersList = responseJson['data'] as List<dynamic>;
      for (final memberData in membersList) {
        MemberModel member = MemberModel.fromJson(memberData);
        members.add(member);
      }
    }
    return members;
  }

  Future<bool> updateMember(MemberModel updatedMember) async {
    final currentMembers = state.value;
    bool isUpdateSuccess = false;

    if (currentMembers == null) return isUpdateSuccess;

    Map<String, dynamic> payload = updatedMember.toJson();
    payload.remove('id');
    payload.remove('kartu');
    payload.remove('createdAt');

    isUpdateSuccess = await _dbManager.updateData(
      endpoint: 'api/mahasiswa',
      dataId: updatedMember.memberId,
      jsonData: payload,
    );

    if (isUpdateSuccess) {
      state = AsyncData([
        for (final member in currentMembers)
          if (member.memberId == updatedMember.memberId) updatedMember else member,
      ]);
    }

    return isUpdateSuccess;
  }
}
