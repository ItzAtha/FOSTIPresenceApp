import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/core/app_constants.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/connectivity_utils.dart';
import '../../../../shared/provider/members_notifier.dart';
import '../../../../translations/locale_keys.g.dart';
import '../widgets/member_card_widget.dart';

part 'members_page.freezed.dart';

@freezed
abstract class FilterIndexSelection with _$FilterIndexSelection {
  const factory FilterIndexSelection({int? divisionIndex, int? generationIndex}) =
      _FilterIndexSelection;
}

@freezed
abstract class MemberFilterQuery with _$MemberFilterQuery {
  const factory MemberFilterQuery({String? divisionName, String? generationName}) =
      _MemberFilterQuery;
}

class MemberPage extends ConsumerStatefulWidget {
  const MemberPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MemberPageState();
}

class _MemberPageState extends ConsumerState<MemberPage> {
  int currentPage = 1;
  String searchQuery = "";
  static const int maxMemberPerPage = 12;

  Divisions? selectedDivision;
  MemberFilterQuery? filterQuery;
  FilterIndexSelection selectedFilterIndex = const FilterIndexSelection();

  final List<Divisions> divisionList = [
    Divisions.ristek,
    Divisions.hubpub,
    Divisions.keor,
    Divisions.bphi,
  ];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberNIMController = TextEditingController();
  final TextEditingController searchBarController = TextEditingController();

  Future<void> memberEditButton({
    required List<MemberModel> membersData,
    required MemberModel memberData,
  }) async {
    MemberModel member = memberData;

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

    memberNameController.text = member.name;
    memberNIMController.text = member.nim;
    setState(() => selectedDivision = member.division);

    var memberEditDialog = StatefulBuilder(
      builder: (context, dialogSetState) {
        return AlertDialog(
          title: Text(
            LocaleKeys.member_page_dialog_title.tr(context: context),
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
                    controller: memberNameController,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: LocaleKeys.member_page_dialog_field_name.tr(context: context),
                      hintText: "Andi Setya Budi",
                      icon: const Icon(Icons.person, size: 24.0),
                      border: const OutlineInputBorder(),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value.toString().isEmpty) {
                        return LocaleKeys.member_page_dialog_validation_name_required.tr(
                          context: context,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: memberNIMController,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: LocaleKeys.member_page_dialog_field_nim.tr(context: context),
                      hintText: "L200250001",
                      icon: const Icon(Icons.perm_identity, size: 24.0),
                      border: const OutlineInputBorder(),
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      bool isValidFormat = RegExp(r'^[A-Z][0-9]+$').hasMatch(value ?? '');
                      bool isNIMExists = membersData.any(
                        (user) => user.nim == value && user.memberId != member.memberId,
                      );

                      if (value.toString().isEmpty) {
                        return LocaleKeys.member_page_dialog_validation_nim_required_empty.tr(
                          context: context,
                        );
                      } else if (isNIMExists) {
                        return LocaleKeys.member_page_dialog_validation_nim_required_exists.tr(
                          context: context,
                        );
                      } else if (!isValidFormat) {
                        return LocaleKeys.member_page_dialog_validation_nim_required_invalid.tr(
                          context: context,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.category, size: 24.0),
                      const SizedBox(width: 16.0),
                      DropdownButton<Divisions>(
                        value: selectedDivision,
                        hint: Text(
                          LocaleKeys.member_page_dialog_field_division.tr(context: context),
                        ),
                        items: divisionList.map((item) {
                          return DropdownMenuItem<Divisions>(
                            value: item,
                            child: Text(item.aliases),
                          );
                        }).toList(),
                        onChanged: (Divisions? value) {
                          if (value == selectedDivision) return;
                          dialogSetState(() => selectedDivision = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => validateFormInput(member),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(120, 40),
                  ),
                  child: Text(
                    LocaleKeys.member_page_dialog_button_update.tr(context: context),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 24.0),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    foregroundColor: AppColors.dangerZone,
                    side: const BorderSide(color: AppColors.dangerZone),
                  ),
                  child: Text(LocaleKeys.member_page_dialog_button_cancel.tr(context: context)),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    showDialog(
      context: context,
      animationStyle: const AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (BuildContext context) {
        return memberEditDialog;
      },
    );
  }

  Future<void> validateFormInput(MemberModel memberData) async {
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

        if (!mounted) return;
        final updatedMember = memberData.copyWith(
          name: memberNameController.text,
          nim: memberNIMController.text,
          division: selectedDivision!,
        );

        ref.read(membersProvider.notifier).updateMember(updatedMember);
        context.pop();
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
            LocaleKeys.member_page_loading_data_process.tr(context: context),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget noMembers() {
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
                        const Icon(Icons.person, size: 40.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            LocaleKeys.member_page_loading_data_no_data_title.tr(context: context),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    const Divider(color: Colors.grey, thickness: 1.5),
                    const SizedBox(height: 8.0),
                    Text(
                      LocaleKeys.member_page_loading_data_no_data_description.tr(context: context),
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

  Widget hasMembers(List<MemberModel> members) {
    List<MemberModel> filteredMembers = [];

    filteredMembers = members.where((member) {
      return member.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (filterQuery != null) {
      filteredMembers = filteredMembers.where((member) {
        final String memberGeneration = member.nim.substring(4, 6);

        final bool isDivisionMatch =
            filterQuery!.divisionName == null ||
            member.division.name.toLowerCase() == filterQuery!.divisionName!.toLowerCase();

        final bool isGenerationMatch =
            filterQuery!.generationName == null || memberGeneration == filterQuery!.generationName!;

        return isDivisionMatch && isGenerationMatch;
      }).toList();
    }

    final totalPages = (filteredMembers.length / maxMemberPerPage).ceil();
    if (totalPages > 0 && currentPage > totalPages) {
      currentPage = totalPages;
    }

    final startIndex = (currentPage - 1) * maxMemberPerPage;
    final endIndex = (startIndex + maxMemberPerPage).clamp(0, filteredMembers.length);
    final currentMembers = filteredMembers.sublist(startIndex, endIndex);

    return Column(
      children: <Widget>[
        Container(
          height: 50.0,
          margin: const EdgeInsets.all(AppSizes.p16),
          child: Row(
            children: <Widget>[
              Expanded(
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
                  hintText: LocaleKeys.search_bar_member.tr(context: context),
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) {
                    setState(() {
                      searchQuery = value;
                      currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              SizedBox(
                width: 45.0,
                height: 45.0,
                child: Material(
                  elevation: Theme.of(context).iconButtonTheme.style?.elevation?.resolve({}) ?? 4.0,
                  shape: Theme.of(context).iconButtonTheme.style?.shape?.resolve({}),
                  child: IconButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();

                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        builder: (context) {
                          return FilterSelectorMenu(
                            filterData: selectedFilterIndex,
                            onFilterSelected: (query) => setState(() => filterQuery = query),
                            onFilterChange: (updatedFilter) => selectedFilterIndex = updatedFilter,
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.filter_list, size: 20.0),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: <Widget>[
                AnimationLimiter(
                  child: Column(
                    children: List<Widget>.generate(currentMembers.length, (index) {
                      final memberData = currentMembers[index];

                      return Column(
                        children: <Widget>[
                          AnimationConfiguration.staggeredList(
                            position: index,
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: MemberCardWidget(
                                  name: memberData.name,
                                  nim: memberData.nim,
                                  division: memberData.division,
                                  editButton: () => memberEditButton(
                                    membersData: members,
                                    memberData: memberData,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (index < currentMembers.length - 1) const SizedBox(height: 16.0),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16.0),
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
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      body: membersAsync.when(
        loading: () => loadingData(),
        error: (error, stackTrace) => noMembers(),
        data: (members) {
          if (members.isEmpty) {
            return noMembers();
          }

          return hasMembers(members);
        },
      ),
    );
  }
}

enum MemberFilterType { division, generation }

class FilterSelectorMenu extends StatefulWidget {
  const FilterSelectorMenu({
    super.key,
    required this._filterData,
    required this._onFilterSelected,
    required this._onFilterChange,
  });

  final FilterIndexSelection _filterData;
  final ValueChanged<MemberFilterQuery?> _onFilterSelected;
  final ValueChanged<FilterIndexSelection> _onFilterChange;

  @override
  State<StatefulWidget> createState() => _FilterSelectorMenuState();
}

class _FilterSelectorMenuState extends State<FilterSelectorMenu> {
  final List<Divisions> divisions = [
    Divisions.ristek,
    Divisions.keor,
    Divisions.hubpub,
    Divisions.bphi,
  ];
  final List<int> generation = [];

  late FilterIndexSelection filterSelectionData;
  late MemberFilterQuery filteredSelectionName;

  @override
  void initState() {
    super.initState();
    filterSelectionData = widget._filterData;
    filteredSelectionName = const MemberFilterQuery();

    int currentYear = DateTime.now().year;
    generation.addAll(List.generate(4, (index) => currentYear - 3 + index));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSizes.p16,
          right: AppSizes.p16,
          bottom: AppSizes.p24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Filters Members",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Text(
              "Sort by Division",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(thickness: 0.8, height: 10.0),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.spaceEvenly,
              children: List<Widget>.generate(divisions.length, (index) {
                return FilterChip(
                  label: Text(
                    divisions[index].aliases,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      filterSelectionData = filterSelectionData.copyWith(
                        divisionIndex: selected ? index : null,
                      );

                      filteredSelectionName = MemberFilterQuery(
                        divisionName: selected ? divisions[index].name : null,
                        generationName: filteredSelectionName.generationName,
                      );
                    });

                    widget._onFilterChange(filterSelectionData);
                  },
                  selected: filterSelectionData.divisionIndex != null
                      ? filterSelectionData.divisionIndex == index
                      : false,
                );
              }),
            ),
            const SizedBox(height: 16.0),
            Text(
              "Sort by Generation",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(thickness: 0.8, height: 10.0),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.spaceEvenly,
              children: List<Widget>.generate(generation.length, (index) {
                return FilterChip(
                  label: Text(
                    generation[index].toString(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      filterSelectionData = filterSelectionData.copyWith(
                        generationIndex: selected ? index : null,
                      );

                      filteredSelectionName = MemberFilterQuery(
                        divisionName: filteredSelectionName.divisionName,
                        generationName: selected ? generation[index].toString().substring(2) : null,
                      );
                    });

                    widget._onFilterChange(filterSelectionData);
                  },
                  selected: filterSelectionData.generationIndex != null
                      ? filterSelectionData.generationIndex == index
                      : false,
                );
              }),
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        filterSelectionData = const FilterIndexSelection();
                      });
                      widget._onFilterSelected(null);
                      widget._onFilterChange(filterSelectionData);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                      side: BorderSide(color: Colors.grey.shade600),
                    ),
                    child: Text("Clear", style: Theme.of(context).textTheme.labelLarge),
                  ),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget._onFilterSelected(filteredSelectionName);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                    ),
                    child: Text(
                      "Apply",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
