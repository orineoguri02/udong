import 'package:flutter/material.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import 'package:udon/core/widgets/calendar-picker.dart';

class BirthAdoptDateSection extends StatefulWidget {
  final String initialBirthDate;
  final String initialAdoptDate;
  final ValueChanged<DateTime?>? onBirthChanged;
  final ValueChanged<DateTime?>? onAdoptChanged;

  const BirthAdoptDateSection({
    super.key,
    required this.initialBirthDate,
    required this.initialAdoptDate,
    this.onBirthChanged,
    this.onAdoptChanged,
  });

  @override
  State<BirthAdoptDateSection> createState() => _BirthAdoptDateSectionState();
}

class _BirthAdoptDateSectionState extends State<BirthAdoptDateSection> {
  late DateTime? _birthDate;
  late DateTime? _adoptDate;

  @override
  void initState() {
    super.initState();
    _birthDate = _parseDate(widget.initialBirthDate);
    _adoptDate = _parseDate(widget.initialAdoptDate);
    _clampAdoptToBirth();
  }

  @override
  void didUpdateWidget(covariant BirthAdoptDateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBirthDate != widget.initialBirthDate ||
        oldWidget.initialAdoptDate != widget.initialAdoptDate) {
      _birthDate = _parseDate(widget.initialBirthDate);
      _adoptDate = _parseDate(widget.initialAdoptDate);
      _clampAdoptToBirth();
    }
  }

  void _clampAdoptToBirth() {
    if (_birthDate != null &&
        _adoptDate != null &&
        _adoptDate!.isBefore(_birthDate!)) {
      _adoptDate = _birthDate;
    }
  }

  DateTime? _parseDate(String text) {
    try {
      final parts = text.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 생년월일: 오늘·미래 선택 불가 (어제까지)
  static DateTime get _yesterday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 1));
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickBirth() async {
    final initial = _birthDate ?? _yesterday;
    final result = await showCalendarPicker(
      context,
      initialDate: initial.isAfter(_yesterday) ? _yesterday : initial,
      firstDate: DateTime(2000, 1, 1),
      lastDate: _yesterday,
    );
    if (result != null) {
      setState(() {
        _birthDate = result;
        if (_adoptDate != null && _adoptDate!.isBefore(result)) {
          _adoptDate = result;
          widget.onAdoptChanged?.call(result);
        }
      });
      widget.onBirthChanged?.call(result);
    }
  }

  Future<void> _pickAdopt() async {
    final minAdopt = _birthDate ?? DateTime(2000, 1, 1);
    final today = _today;
    final initial = _adoptDate ?? (today.isBefore(minAdopt) ? minAdopt : today);
    final clampedInitial = initial.isBefore(minAdopt)
        ? minAdopt
        : (initial.isAfter(today) ? today : initial);
    final result = await showCalendarPicker(
      context,
      initialDate: clampedInitial,
      firstDate: minAdopt, // 입양일은 생년월일보다 이전 불가 (같은 날 가능)
      lastDate: today,
    );
    if (result != null) {
      setState(() => _adoptDate = result);
      widget.onAdoptChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17.s),
      child: Row(
        children: [
          Expanded(
            child: PetDateField(
              label: '생년월일',
              value: _formatDate(_birthDate),
              onTap: _pickBirth,
            ),
          ),
          SizedBox(width: 16.s),
          Expanded(
            child: PetDateField(
              label: '입양일자',
              value: _formatDate(_adoptDate),
              onTap: _pickAdopt,
            ),
          ),
        ],
      ),
    );
  }
}

class PetDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final double? width;

  const PetDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 13.s),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13.s,
              fontWeight: FontWeight.w700,
              color: AppColors.font,
            ),
          ),
        ),
        SizedBox(height: 8.s),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width ?? 156.s,
            padding: EdgeInsets.symmetric(horizontal: 14.s, vertical: 6.s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23.397.s),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.20),
                  blurRadius: 2.865.s,
                  spreadRadius: 0.18.s,
                ),
              ],
            ),
            child: Text(
              value.isEmpty ? '눌러서 선택' : value,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13.s,
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? AppColors.fontMuted : AppColors.font,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
