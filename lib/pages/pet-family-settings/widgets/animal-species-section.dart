import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../features/home/models/animal-species.dart';

class AnimalSpeciesSection extends StatefulWidget {
  final int categoryIndex;

  /// (그룹명 예: 도마뱀, 세부종 예: 레오파드 게코)
  final void Function(String? groupName, String? species)? onSpeciesSelected;
  final VoidCallback? onSave;

  const AnimalSpeciesSection({
    super.key,
    required this.categoryIndex,
    this.onSpeciesSelected,
    this.onSave,
  });

  @override
  State<AnimalSpeciesSection> createState() => _AnimalSpeciesSectionState();
}

class _AnimalSpeciesSectionState extends State<AnimalSpeciesSection> {
  int? _selectedGroupIndex;
  String? _selectedSpecies;
  late TextEditingController _directInputController;
  late FocusNode _directInputFocusNode;
  // 그룹별 직접입력 텍스트 저장 (예: 도마뱀 그룹 안의 직접입력만 별도 유지)
  final Map<int, String> _directTexts = {};

  static const int _directInputMaxLength = 20;

  @override
  void initState() {
    super.initState();
    _directInputController = TextEditingController();
    _directInputController.addListener(_onDirectInputChanged);
    _directInputFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _directInputController.removeListener(_onDirectInputChanged);
    _directInputController.dispose();
    _directInputFocusNode.dispose();
    super.dispose();
  }

  void _onDirectInputChanged() {
    if (_selectedSpecies != '직접입력') return;
    final text = _directInputController.text.trim();
    final groupName =
        _selectedGroupIndex != null &&
            (animalSpeciesMap[widget.categoryIndex]?.length ?? 0) >
                _selectedGroupIndex!
        ? animalSpeciesMap[widget.categoryIndex]![_selectedGroupIndex!].name
        : null;
    if (_selectedGroupIndex != null) {
      _directTexts[_selectedGroupIndex!] = text;
    }
    widget.onSpeciesSelected?.call(groupName, text.isEmpty ? '직접입력' : text);
  }

  @override
  void didUpdateWidget(AnimalSpeciesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIndex != widget.categoryIndex) {
      _selectedGroupIndex = null;
      _selectedSpecies = null;
      _directInputController.clear();
      _directTexts.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final groups = animalSpeciesMap[widget.categoryIndex] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groups.asMap().entries.map(
          (e) => _SpeciesGroup(
            group: e.value,
            groupIndex: e.key,
            selectedGroupIndex: _selectedGroupIndex,
            selectedSpecies: _selectedSpecies,
            directInputController: _directInputController,
            directInputText: _directTexts[e.key],
            directInputFocusNode: _directInputFocusNode,
            directInputMaxLength: _directInputMaxLength,
            onSelect: (groupIndex, species) {
              final groupName = groups[groupIndex].name;
              setState(() {
                _selectedGroupIndex = groupIndex;
                _selectedSpecies = species;
              });

              if (species == '직접입력') {
                // 이 그룹에 이전에 입력한 값이 있으면 복원
                final previous = _directTexts[groupIndex];
                if (previous != null && previous.trim().isNotEmpty) {
                  _directInputController.text = previous;
                  _directInputController.selection = TextSelection.collapsed(
                    offset: previous.length,
                  );
                }
                // 한 번의 탭으로 바로 커서가 뜨도록 다음 프레임에 포커스 요청
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  FocusScope.of(context).requestFocus(_directInputFocusNode);
                });
              }

              widget.onSpeciesSelected?.call(
                groupName,
                species == '직접입력' ? '직접입력' : species,
              );
            },
          ),
        ),
        if (widget.onSave != null) ...[
          SizedBox(height: 20.s),
          Center(
            child: GestureDetector(
              onTap: widget.onSave,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 36.s, vertical: 10.s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.s),
                  border: Border.all(color: AppColors.main, width: 1.s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 4.s,
                      offset: Offset(0, 1.s),
                    ),
                  ],
                ),
                child: Text(
                  '저장하기',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 14.s,
                    fontWeight: FontWeight.w800,
                    color: AppColors.main,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeciesGroup extends StatelessWidget {
  final AnimalSpeciesGroup group;
  final int groupIndex;
  final int? selectedGroupIndex;
  final String? selectedSpecies;
  final TextEditingController? directInputController;
  final String? directInputText;
  final FocusNode? directInputFocusNode;
  final int directInputMaxLength;
  final void Function(int groupIndex, String species) onSelect;

  const _SpeciesGroup({
    required this.group,
    required this.groupIndex,
    required this.selectedGroupIndex,
    required this.selectedSpecies,
    this.directInputController,
    this.directInputText,
    this.directInputFocusNode,
    this.directInputMaxLength = 20,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 19.s),
            child: Text(
              group.name,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 14.s,
                fontWeight: FontWeight.w700,
                color: AppColors.font,
              ),
            ),
          ),
          SizedBox(height: 8.s),
          Padding(
            padding: EdgeInsets.only(left: 15.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.s,
                  runSpacing: 8.s,
                  children: group.subSpecies
                      .where((s) => s != '직접입력')
                      .map(
                        (species) => _SpeciesChip(
                          label: species,
                          isSelected:
                              selectedGroupIndex == groupIndex &&
                              selectedSpecies == species,
                          onTap: () => onSelect(groupIndex, species),
                        ),
                      )
                      .toList(),
                ),
                if (directInputController != null) ...[
                  SizedBox(height: 8.s),
                  Padding(
                    padding: EdgeInsets.only(left: 0.s),
                    child:
                        selectedGroupIndex == groupIndex &&
                            selectedSpecies == '직접입력'
                        ? _DirectInputChip(
                            controller: directInputController!,
                            focusNode: directInputFocusNode,
                            maxLength: directInputMaxLength,
                          )
                        : _SpeciesChip(
                            label: (directInputText ?? '').trim().isEmpty
                                ? '직접입력'
                                : (directInputText ?? '').trim(),
                            isSelected: false,
                            onTap: () => onSelect(groupIndex, '직접입력'),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeciesChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.s, vertical: 8.s),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.main : Colors.white,
          borderRadius: BorderRadius.circular(30.s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4.s,
              offset: Offset(0, 1.s),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14.s,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF737373),
            height: 25.289 / 14,
          ),
        ),
      ),
    );
  }
}

class _DirectInputChip extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int maxLength;

  const _DirectInputChip({
    required this.controller,
    required this.focusNode,
    required this.maxLength,
  });

  @override
  State<_DirectInputChip> createState() => _DirectInputChipState();
}

class _DirectInputChipState extends State<_DirectInputChip> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    // 허공 터치로 포커스가 빠질 때 입력값을 확정(트림)해서 칩에 그대로 보이게
    if (!(widget.focusNode?.hasFocus ?? false)) {
      final trimmed = widget.controller.text.trim();
      if (trimmed != widget.controller.text) {
        widget.controller.text = trimmed;
        widget.controller.selection = TextSelection.collapsed(
          offset: trimmed.length,
        );
      }
    }
    setState(() {});
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final text = widget.controller.text;
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    // 글자당 13px 기준, 패딩 포함. 빈 상태에서도 "직접입력" 텍스트가 다 들어갈 최소 너비 확보
    final len = text.isEmpty ? 5 : text.length.clamp(1, widget.maxLength);
    final contentWidth = (len * 13.0).s + 32.s;
    final width = math.max(100.s, contentWidth);

    final chipPadding = EdgeInsets.symmetric(horizontal: 12.s, vertical: 8.s);

    if (!hasFocus) {
      // 포커스 해제 시: 주황색 아웃라인 + 흰 배경, 글자는 폰트 컬러
      return GestureDetector(
        onTap: () {
          if (widget.focusNode != null) {
            FocusScope.of(context).requestFocus(widget.focusNode);
          }
        },
        child: Container(
          width: width,
          padding: chipPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.s),
            border: Border.all(color: AppColors.main, width: 1.s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4.s,
                offset: Offset(0, 1.s),
              ),
            ],
          ),
          child: Text(
            text.isEmpty ? '직접입력' : text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 14.s,
              fontWeight: FontWeight.w400,
              color: AppColors.font,
              height: 25.289 / 14,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      padding: chipPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.s),
        border: Border.all(color: AppColors.main, width: 1.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4.s,
            offset: Offset(0, 1.s),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLength: widget.maxLength,
        autofocus: true,
        maxLines: 1,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14.s,
          fontWeight: FontWeight.w400,
          color: AppColors.font,
          height: 25.289 / 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(
            left: 8.s,
            right: 2.s,
            top: 0,
            bottom: 0,
          ),
          hintText: '직접입력',
          hintStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14.s,
            color: AppColors.fontMuted,
          ),
        ),
      ),
    );
  }
}
