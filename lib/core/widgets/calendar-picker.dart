/// 공통 캘린더 날짜 선택 다이얼로그
///
/// - core/widgets 에서 재사용 (반려동물 생일/입양일 등)

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';

/// 날짜 선택 다이얼로그 호출
Future<DateTime?> showCalendarPicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black45,
    barrierDismissible: true,
    builder: (_) => _CalendarPickerDialog(
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _CalendarPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _CalendarPickerDialog({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  late DateTime _viewMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _viewMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _prevMonth() => setState(() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
  });

  void _onMonthChanged(int month) {
    setState(() => _viewMonth = DateTime(_viewMonth.year, month));
  }

  void _onYearChanged(int year) {
    setState(() => _viewMonth = DateTime(year, _viewMonth.month));
  }

  List<DateTime?> _buildDays() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final last = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = first.weekday % 7; // 0=Sun
    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_viewMonth.year, _viewMonth.month, d));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final days = _buildDays();
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width - 24.s,
          constraints: BoxConstraints(minHeight: 400.s),
          padding: EdgeInsets.fromLTRB(24.s, 22.s, 24.s, 24.s),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(27.s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14.s,
                offset: Offset(0, 5.s),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더: 월·년 드롭다운 + 이전/다음
              Row(
                children: [
                  CalendarMonthYearDropdown(
                    month: _viewMonth.month,
                    year: _viewMonth.year,
                    onMonthChanged: _onMonthChanged,
                    onYearChanged: _onYearChanged,
                  ),
                  const Spacer(),
                  _NavButton(isLeft: true, onTap: _prevMonth),
                  SizedBox(width: 8.s),
                  _NavButton(isLeft: false, onTap: _nextMonth),
                ],
              ),
              SizedBox(height: 18.s),
              // 요일 헤더
              Row(
                children: weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: 14.s,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFB57D),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 10.s),
              // 날짜 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  mainAxisExtent: 48.s,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  if (day == null) return const SizedBox.shrink();

                  final today = DateTime.now();
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  final firstAllowed = widget.firstDate == null
                      ? null
                      : DateTime(
                          widget.firstDate!.year,
                          widget.firstDate!.month,
                          widget.firstDate!.day,
                        );
                  final lastAllowed = widget.lastDate == null
                      ? null
                      : DateTime(
                          widget.lastDate!.year,
                          widget.lastDate!.month,
                          widget.lastDate!.day,
                        );

                  final isBeforeFirst =
                      firstAllowed != null && dateOnly.isBefore(firstAllowed);
                  final isAfterLast =
                      lastAllowed != null && dateOnly.isAfter(lastAllowed);
                  final isDisabled = isBeforeFirst || isAfterLast;

                  final isSelected =
                      day.year == _selected.year &&
                      day.month == _selected.month &&
                      day.day == _selected.day;

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() => _selected = day);
                            Navigator.pop(context, day);
                          },
                    child: Container(
                      margin: EdgeInsets.all(3.s),
                      decoration: BoxDecoration(
                        color: isSelected && !isDisabled
                            ? const Color(0xFFFFB57D)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 15.s,
                          fontWeight: FontWeight.w700,
                          color: isDisabled
                              ? const Color(0xFFBDBDBD)
                              : (isSelected
                                    ? Colors.white
                                    : const Color(0xFF383838)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 헤더용 월·년 드롭다운 (아래 화살표 탭 시 리스트 표시)
/// 반려가족 설정·상태기록 등에서 동일한 연/월 선택 방식으로 재사용
/// [yearWidth], [monthWidth], [buttonHeight] 등으로 호출처 디자인 유지 가능
class CalendarMonthYearDropdown extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  /// 스타일 오버라이드 (미지정 시 반려가족 설정 다이얼로그용 기본값)
  final double? yearWidth;
  final double? monthWidth;
  final double? buttonHeight;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? fontSize;
  final double? iconSize;
  final String Function(int)? yearLabelBuilder;
  final double? gapBetween;
  final TextOverflow? textOverflow;

  static const int minYear = 2000;
  static const int maxYear = 2030;

  const CalendarMonthYearDropdown({
    super.key,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
    this.yearWidth,
    this.monthWidth,
    this.buttonHeight,
    this.backgroundColor,
    this.borderRadius,
    this.fontSize,
    this.iconSize,
    this.yearLabelBuilder,
    this.gapBetween,
    this.textOverflow,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final bg = backgroundColor ?? const Color.fromRGBO(255, 150, 69, 0.70);
    final gap = gapBetween ?? 8.s;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderDropdown<int>(
          value: year,
          items: List.generate(maxYear - minYear + 1, (i) => minYear + i),
          labelBuilder: yearLabelBuilder ?? (v) => '$v',
          onChanged: (v) {
            if (v != null) onYearChanged(v);
          },
          backgroundColor: bg,
          width: yearWidth ?? 85.s,
          buttonHeight: buttonHeight,
          borderRadius: borderRadius,
          fontSize: fontSize,
          iconSize: iconSize,
          textOverflow: textOverflow,
        ),
        SizedBox(width: gap),
        _HeaderDropdown<int>(
          value: month,
          items: List.generate(12, (i) => i + 1),
          labelBuilder: (v) => '$v월',
          onChanged: (v) {
            if (v != null) onMonthChanged(v);
          },
          backgroundColor: bg,
          width: monthWidth ?? 60.s,
          buttonHeight: buttonHeight,
          borderRadius: borderRadius,
          fontSize: fontSize,
          iconSize: iconSize,
          textOverflow: textOverflow,
        ),
      ],
    );
  }
}

class _HeaderDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final Color backgroundColor;
  final double width;
  final double? buttonHeight;
  final double? borderRadius;
  final double? fontSize;
  final double? iconSize;
  final TextOverflow? textOverflow;

  const _HeaderDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.backgroundColor,
    required this.width,
    this.buttonHeight,
    this.borderRadius,
    this.fontSize,
    this.iconSize,
    this.textOverflow,
  });

  static const Color _menuBorderColor = Color(0xFF383838);
  static final Color _dividerColor = Color.fromRGBO(56, 56, 56, 0.10);

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    SizeConfig.init(context);
    final overlayState = Overlay.of(context);
    final overlay = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;
    final menuW = width;
    final left = pos.dx + (size.width - menuW) / 2;
    final top = pos.dy + size.height;

    final completer = Completer<T?>();
    late OverlayEntry entry;

    void close(T? value) {
      if (!completer.isCompleted) {
        entry.remove();
        completer.complete(value);
      }
    }

    entry = OverlayEntry(
      builder: (ctx) => _DropdownMenuOverlay<T>(
        left: left,
        top: top,
        menuWidth: menuW,
        items: items,
        labelBuilder: labelBuilder,
        dividerColor: _dividerColor,
        menuBorderColor: _menuBorderColor,
        onSelect: close,
      ),
    );
    overlayState.insert(entry);

    final selected = await completer.future;
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final height = buttonHeight ?? 36.s;
    final radius = borderRadius ?? 5.s;
    final fs = fontSize ?? 13.s;
    final icon = iconSize ?? 17.s;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _openMenu(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.s, vertical: 4.s),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  labelBuilder(value),
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  overflow: textOverflow ?? TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.s),
              Icon(Icons.keyboard_arrow_down, size: icon, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// 버튼 하단을 기준으로 아래로 펼쳐지는 드롭다운 메뉴
class _DropdownMenuOverlay<T> extends StatefulWidget {
  final double left;
  final double top;
  final double menuWidth;
  final List<T> items;
  final String Function(T) labelBuilder;
  final Color dividerColor;
  final Color menuBorderColor;
  final void Function(T?) onSelect;

  const _DropdownMenuOverlay({
    required this.left,
    required this.top,
    required this.menuWidth,
    required this.items,
    required this.labelBuilder,
    required this.dividerColor,
    required this.menuBorderColor,
    required this.onSelect,
  });

  @override
  State<_DropdownMenuOverlay<T>> createState() =>
      _DropdownMenuOverlayState<T>();
}

class _DropdownMenuOverlayState<T> extends State<_DropdownMenuOverlay<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMenuContent() {
    return Material(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.s),
        side: BorderSide(color: widget.menuBorderColor, width: 1.143.s),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.menuWidth,
          maxHeight: 280.s,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < widget.items.length; i++) ...[
              if (i > 0)
                Center(
                  child: Container(
                    width: 43.s,
                    height: 0.5.s,
                    color: widget.dividerColor,
                  ),
                ),
              InkWell(
                onTap: () => widget.onSelect(widget.items[i]),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.s,
                    vertical: 10.s,
                  ),
                  child: Center(
                    child: Text(
                      widget.labelBuilder(widget.items[i]),
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 13.s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.font,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelect(null),
          ),
        ),
        Positioned(
          left: widget.left,
          top: widget.top,
          child: SizeTransition(
            sizeFactor: _animation,
            axisAlignment: -1,
            child: _buildMenuContent(),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onTap;

  const _NavButton({required this.isLeft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return GestureDetector(
      onTap: onTap,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationZ(isLeft ? 3.14159 : 0),
        child: Image.asset(
          'assets/images/mypage/next-icon.webp',
          width: 36.s,
          height: 36.s,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
