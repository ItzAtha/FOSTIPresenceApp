import 'package:attendance_management/manager/database_manager.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'members_notifier.g.dart';

@riverpod
class MembersNotifier extends _$MembersNotifier {
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
        print(member.toJson());
      }
    }
    return members;
  }

  void updateMember(MemberModel updatedMember) {
    final currentMembers = state.value;

    if (currentMembers == null) return;
    state = AsyncData([
      for (final member in currentMembers)
        if (member.memberId == updatedMember.memberId) updatedMember else member,
    ]);
  }
}
