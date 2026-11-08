import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';

// 오늘의 상태 기록하기 - 개별 카드 위젯 모음

// ───────────────────────────────────────────────────────────
// Page 1 카드
// ───────────────────────────────────────────────────────────

class TodayMealCard extends StatelessWidget {
  final bool mealDone;
  final bool mealDetailVisible;
  final int mealTypeIndex;
  final ValueChanged<bool> onMealDoneChanged;
  final ValueChanged<int> onMealTypeChanged;
  final TimeOfDay feedTime;
  final ValueChanged<TimeOfDay> onFeedTimeChanged;

  const TodayMealCard({
    super.key,
    required this.mealDone,
    required this.mealDetailVisible,
    required this.mealTypeIndex,
    required this.onMealDoneChanged,
    required this.onMealTypeChanged,
    required this.feedTime,
    required this.onFeedTimeChanged,
  });

  static const _duration = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '식사',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(mealDetailVisible),
                      tween: Tween<double>(
                        begin: mealDetailVisible ? 0 : 1,
                        end: mealDetailVisible ? 1 : 0,
                      ),
                      duration: _duration,
                      curve: _curve,
                      builder: (context, value, _) {
                        final w = maxW + (192.s - maxW) * value;
                        return SizedBox(
                          width: w,
                          child: _OXToggle(
                            isOSelected: mealDone,
                            onToggle: () => onMealDoneChanged(!mealDone),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Flexible(
                flex: mealDetailVisible ? 0 : 0,
                child: AnimatedSize(
                  duration: _duration,
                  curve: _curve,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: _curve,
                    switchOutCurve: _curve,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: _curve,
                      ),
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(parent: animation, curve: _curve),
                            ),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) =>
                        current ?? const SizedBox.shrink(),
                    child: mealDetailVisible
                        ? Row(
                            key: const ValueKey('clock-visible'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 10.s),
                              SizedBox(
                                width: 118.s,
                                child: _TimeDisplay(
                                  time: feedTime,
                                  onTimeChanged: onFeedTimeChanged,
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            key: const ValueKey('clock-hidden'),
                            width: 0,
                            height: 34.s,
                          ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: _duration,
            curve: _curve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _duration,
              switchInCurve: _curve,
              switchOutCurve: _curve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: _curve),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: _curve)),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) =>
                  current ?? const SizedBox.shrink(),
              child: mealDetailVisible
                  ? Column(
                      key: const ValueKey('buttons-visible'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 14.s),
                        Row(
                          children: [
                            _LogButton(
                              label: '잘 먹음',
                              selected: mealTypeIndex == 0,
                              onTap: () => onMealTypeChanged(0),
                            ),
                            SizedBox(width: 7.s),
                            _LogButton(
                              label: '조금 먹음',
                              selected: mealTypeIndex == 1,
                              onTap: () => onMealTypeChanged(1),
                            ),
                            SizedBox(width: 7.s),
                            _LogButton(
                              label: '안 먹음',
                              selected: mealTypeIndex == 2,
                              onTap: () => onMealTypeChanged(2),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox(
                      key: ValueKey('buttons-hidden'),
                      height: 0,
                      width: double.infinity,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayBowelCard extends StatelessWidget {
  final int bowelIndex;
  final ValueChanged<int> onChanged;

  const TodayBowelCard({
    super.key,
    required this.bowelIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '배변',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LogButtonWide(
                  label: '정상',
                  selected: bowelIndex == 0,
                  onTap: () => onChanged(0),
                ),
              ),
              SizedBox(width: 7.s),
              Expanded(
                child: _LogButtonWide(
                  label: '오늘 안함',
                  selected: bowelIndex == 1,
                  onTap: () => onChanged(1),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.s),
          Row(
            children: [
              Expanded(
                child: _LogButtonWide(
                  label: '설사',
                  selected: bowelIndex == 2,
                  onTap: () => onChanged(2),
                ),
              ),
              SizedBox(width: 7.s),
              Expanded(
                child: _LogButtonWide(
                  label: '변비',
                  selected: bowelIndex == 3,
                  onTap: () => onChanged(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TodayWeightCard extends StatelessWidget {
  final TextEditingController controller;
  final bool unitIsKg;
  final VoidCallback onUnitToggle;

  const TodayWeightCard({
    super.key,
    required this.controller,
    required this.unitIsKg,
    required this.onUnitToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '체중',
      child: _WeightField(
        controller: controller,
        unitIsKg: unitIsKg,
        onUnitTap: onUnitToggle,
      ),
    );
  }
}

class TodayAppearanceCard extends StatelessWidget {
  final int appearanceIndex;
  final ValueChanged<int> onChanged;
  final TextEditingController memoController;
  final String? initialPhotoPath;
  final ValueChanged<String?> onPhotoChanged;

  const TodayAppearanceCard({
    super.key,
    required this.appearanceIndex,
    required this.onChanged,
    required this.memoController,
    this.initialPhotoPath,
    required this.onPhotoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '외관',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _LogButtonWide(
                  label: '정상',
                  selected: appearanceIndex == 0,
                  onTap: () => onChanged(0),
                  textColor: AppColors.main,
                ),
              ),
              SizedBox(width: 7.s),
              Expanded(
                child: _LogButtonWide(
                  label: '이상있음',
                  selected: appearanceIndex == 1,
                  onTap: () => onChanged(1),
                  selectedBg: const Color(0x1AFF4545),
                  selectedText: const Color(0xFFFF4545),
                  selectedBorder: const Color(0x33FF4545),
                  textColor: const Color(0xFFFF4545),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.s),
          _PhotoArea(initialPath: initialPhotoPath, onChanged: onPhotoChanged),
          SizedBox(height: 14.s),
          Text(
            '추가 메모 작성',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w700,
              color: const Color(0x80383838),
            ),
          ),
          SizedBox(height: 6.s),
          _MemoField(
            controller: memoController,
            // Page 1: 카드 내부 메모는 외곽선 없이 라인만 보이게
            showBorder: false,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Page 2 카드
// ───────────────────────────────────────────────────────────

class TodayOXCard extends StatelessWidget {
  final String tag;
  final bool isOSelected;
  final ValueChanged<bool> onChanged;

  const TodayOXCard({
    super.key,
    required this.tag,
    required this.isOSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SmallCard(
      tag: tag,
      child: _OXToggle(
        isOSelected: isOSelected,
        onToggle: () => onChanged(!isOSelected),
      ),
    );
  }
}

class TodayTempHumidityCard extends StatelessWidget {
  final TextEditingController tempController;
  final TextEditingController humidityController;

  const TodayTempHumidityCard({
    super.key,
    required this.tempController,
    required this.humidityController,
  });

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '온도 및 습도',
      child: _TempHumidityBox(
        tempController: tempController,
        humidityController: humidityController,
      ),
    );
  }
}

class TodayMemoCard extends StatelessWidget {
  final TextEditingController memoController;

  const TodayMemoCard({super.key, required this.memoController});

  @override
  Widget build(BuildContext context) {
    return _QuickCard(
      tag: '메모',
      child: _MemoField(controller: memoController, lineCount: 7),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 공통 카드 컨테이너
// ───────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final String tag;
  final Widget child;

  const _QuickCard({required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x33383838)),
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.fromLTRB(24.s, 14.s, 24.s, 18.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tag(label: tag),
          SizedBox(height: 14.s),
          child,
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String tag;
  final Widget child;

  const _SmallCard({required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 107.s,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x33383838)),
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.fromLTRB(14.s, 14.s, 14.s, 14.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tag(label: tag),
          SizedBox(height: 18.s),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 식사·배변·체중·외관 등 타이틀 – 주황색 타원(pill), 곡선 강조
class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.s, vertical: 6.s),
      decoration: ShapeDecoration(
        color: AppColors.main,
        shape: OvalBorder(
          side: BorderSide(color: AppColors.main, width: 1.5.s),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 11.96.s,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.23,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 공통 O/X 토글 & 버튼
// ───────────────────────────────────────────────────────────

class _OXToggle extends StatelessWidget {
  final bool isOSelected;
  final VoidCallback onToggle;

  const _OXToggle({required this.isOSelected, required this.onToggle});

  static const _slideDuration = Duration(milliseconds: 220);
  static const _slideCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final radius = 8.72.s;
    final borderColor = const Color(0x33383838);
    final padding = 0.89.s;
    final innerRadius = radius - padding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerW = constraints.maxWidth - 2 * padding;
        final halfW = innerW / 2;

        return Container(
          height: 34.s,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: EdgeInsets.all(padding),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(isOSelected),
                tween: Tween<double>(
                  begin: isOSelected ? 1 : 0,
                  end: isOSelected ? 0 : 1,
                ),
                duration: _slideDuration,
                curve: _slideCurve,
                builder: (context, value, _) {
                  final left = value * halfW;
                  final onLeft = value < 0.5;
                  return Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: halfW,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.horizontal(
                          left: onLeft
                              ? Radius.circular(innerRadius)
                              : Radius.zero,
                          right: onLeft
                              ? Radius.zero
                              : Radius.circular(innerRadius),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 2.s,
                            offset: Offset(0, 1.s),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isOSelected ? null : onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          '주었다',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: 12.s,
                            fontWeight: FontWeight.w800,
                            color: isOSelected
                                ? AppColors.main
                                : const Color(0x80383838),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: isOSelected ? onToggle : null,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          '안 주었다',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: 12.s,
                            fontWeight: FontWeight.w800,
                            color: isOSelected
                                ? const Color(0x80383838)
                                : AppColors.main,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LogButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34.s,
          decoration: BoxDecoration(
            color: selected ? const Color(0x1AFF9645) : Colors.white,
            borderRadius: BorderRadius.circular(12.46.s),
            border: Border.all(
              color: selected
                  ? const Color(0x33FF9645)
                  : const Color(0x33383838),
              width: 0.89.s,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.46.s,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.main : const Color(0x80383838),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogButtonWide extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBg;
  final Color? selectedText;
  final Color? selectedBorder;

  /// 선택 여부와 관계없이 글자 색 고정 (미지정 시 비선택=회색, 선택=주황/red)
  final Color? textColor;

  const _LogButtonWide({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBg,
    this.selectedText,
    this.selectedBorder,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        textColor ??
        (selected ? (selectedText ?? AppColors.main) : const Color(0x80383838));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 37.44.s,
        decoration: BoxDecoration(
          color: selected
              ? (selectedBg ?? const Color(0x1AFF9645))
              : Colors.white,
          borderRadius: BorderRadius.circular(12.46.s),
          border: Border.all(
            color: selected
                ? (selectedBorder ?? const Color(0x33FF9645))
                : const Color(0x33383838),
            width: 0.89.s,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12.46.s,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 시간 / 체중 / 사진 / 메모 / 온도·습도
// ───────────────────────────────────────────────────────────

class _TimeDisplay extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _TimeDisplay({required this.time, required this.onTimeChanged});

  Future<void> _openPicker(BuildContext context) async {
    // iOS·Android 동일: 스크롤 휠(CupertinoTimerPicker) 바텀시트
    final TimeOfDay? picked = await _showCupertinoTimePicker(context);
    if (!context.mounted) return;
    if (picked != null) onTimeChanged(picked);
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(BuildContext context) async {
    Duration duration = Duration(hours: time.hour, minutes: time.minute);
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CupertinoTimePickerSheet(initialDuration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final radius = 8.47.s;
    final borderW = 0.89.s;
    final leftWidth = 53.s;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')} : ${time.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _openPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34.s,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.main, width: borderW),
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: leftWidth,
              height: 34.s,
              decoration: BoxDecoration(
                color: AppColors.main,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(radius - borderW),
                  right: Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icons/feed-time-icon.webp',
                height: 16.s,
                width: 28.s,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 6.s, right: 8.s),
                child: Center(
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 13.6.s,
                      fontWeight: FontWeight.w800,
                      height: 15 / 13.6,
                      color: AppColors.main,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CupertinoTimerPicker에서 "hour" / "min" 레이블을 숨기기 위한 로컬라이제이션
class _EmptyTimerLabelsCupertinoLocalizations
    extends DefaultCupertinoLocalizations {
  @override
  List<String> get timerPickerHourLabels => const ['', ''];

  @override
  List<String> get timerPickerMinuteLabels => const [''];

  @override
  String timerPickerHourLabel(int hour) => '';

  @override
  String timerPickerMinuteLabel(int minute) => '';
}

class _EmptyTimerLabelsCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _EmptyTimerLabelsCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        _EmptyTimerLabelsCupertinoLocalizations(),
      );

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) => false;
}

class _CupertinoTimePickerSheet extends StatefulWidget {
  final Duration initialDuration;

  const _CupertinoTimePickerSheet({required this.initialDuration});

  @override
  State<_CupertinoTimePickerSheet> createState() =>
      _CupertinoTimePickerSheetState();
}

class _CupertinoTimePickerSheetState extends State<_CupertinoTimePickerSheet> {
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.s)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('취소', style: TextStyle(color: AppColors.main)),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final minutes = _duration.inMinutes;
                      final hour = (minutes ~/ 60) % 24;
                      final minute = minutes % 60;
                      final t = TimeOfDay(hour: hour, minute: minute);
                      Navigator.of(context).pop(t);
                    },
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: AppColors.main,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Localizations.override(
                    context: context,
                    delegates: const [_EmptyTimerLabelsCupertinoDelegate()],
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: _duration,
                      onTimerDurationChanged: (d) =>
                          setState(() => _duration = d),
                    ),
                  ),
                  IgnorePointer(
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 28.s,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPickerSheet extends StatefulWidget {
  final int min;
  final int max;
  final int initial;
  final String unitLabel;
  final String title;

  const _NumberPickerSheet({
    required this.min,
    required this.max,
    required this.initial,
    required this.unitLabel,
    required this.title,
  });

  @override
  State<_NumberPickerSheet> createState() => _NumberPickerSheetState();
}

class _NumberPickerSheetState extends State<_NumberPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final itemCount = widget.max - widget.min + 1;
    final initialIndex = (_selected - widget.min).clamp(0, itemCount - 1);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.s)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.s, vertical: 12.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('취소', style: TextStyle(color: AppColors.main)),
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 15.s,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF383838),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: AppColors.main,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216.s,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                itemExtent: 36.s,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selected = widget.min + index;
                  });
                },
                children: [
                  for (int i = widget.min; i <= widget.max; i++)
                    Center(
                      child: Text(
                        '$i${widget.unitLabel}',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 20.s,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF383838),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  final TextEditingController controller;
  final bool unitIsKg;
  final VoidCallback onUnitTap;

  const _WeightField({
    required this.controller,
    required this.unitIsKg,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.s,
      padding: EdgeInsets.symmetric(horizontal: 12.s),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.main, width: 0.89.s),
        borderRadius: BorderRadius.circular(12.46.s),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 20.s,
                fontWeight: FontWeight.w800,
                color: AppColors.main,
              ),
            ),
          ),
          GestureDetector(
            onTap: onUnitTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.s, vertical: 8.s),
              decoration: BoxDecoration(
                color: AppColors.main,
                borderRadius: BorderRadius.circular(10.28.s),
              ),
              child: Text(
                unitIsKg ? 'Kg' : 'g',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 16.s,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoArea extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String?> onChanged;

  const _PhotoArea({this.initialPath, required this.onChanged});

  @override
  State<_PhotoArea> createState() => _PhotoAreaState();
}

class _PhotoAreaState extends State<_PhotoArea> {
  final ImagePicker _picker = ImagePicker();
  String? _pickedPath;

  @override
  void initState() {
    super.initState();
    _pickedPath = _normalizePath(widget.initialPath);
  }

  @override
  void didUpdateWidget(covariant _PhotoArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPath != widget.initialPath) {
      _pickedPath = _normalizePath(widget.initialPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        if (x != null) {
          setState(() => _pickedPath = x.path);
          widget.onChanged(x.path);
        }
      },
      child: Container(
        height: 196.s,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.46.s),
          border: Border.all(color: const Color(0x33383838), width: 0.89.s),
        ),
        child: _buildImagePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    final path = _normalizePath(_pickedPath);
    if (path == null) return _buildPlaceholder();

    // 웹은 image_picker가 blob: URL을 주므로 network 이미지로 표시한다.
    final image = kIsWeb || _isRemoteUrl(path)
        ? Image.network(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.46.s),
      child: image,
    );
  }

  bool _isRemoteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String? _normalizePath(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/record-state/add_a_photo.webp',
          width: 42.s,
          height: 42.s,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 8.s),
        Text(
          '사진 추가',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 11.s,
            fontWeight: FontWeight.w700,
            color: const Color(0x33383838),
          ),
        ),
      ],
    );
  }
}

/// N줄 메모지 디자인 유지 + 단일 멀티라인 입력 (엔터 시 다음 줄)
class _MemoField extends StatelessWidget {
  final TextEditingController controller;
  final int lineCount;
  final bool showBorder;

  const _MemoField({
    required this.controller,
    this.lineCount = 5,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final lineHeight = 26.s;
    final padV = 8.s;
    final totalHeight = padV * 2 + lineHeight * lineCount;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBorder
            ? Border.all(color: const Color(0x33383838), width: 0.89.s)
            : null,
        borderRadius: BorderRadius.circular(12.46.s),
      ),
      child: Stack(
        children: [
          // 원래 디자인: N줄 구분선 (메모지)
          for (int i = 1; i < lineCount; i++)
            Positioned(
              left: 12.s,
              right: 12.s,
              top: padV + (lineHeight * i).toDouble(),
              height: 1.s,
              child: Container(color: const Color(0x33383838)),
            ),
          // 추가 메모 작성(첫 페이지)일 때만 맨 아래 회색 밑줄
          if (!showBorder)
            Positioned(
              left: 12.s,
              right: 12.s,
              bottom: padV,
              height: 1.s,
              child: Container(color: const Color(0x33383838)),
            ),
          // 단일 멀티라인 입력 (배경 투명해 구분선이 보임)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.s, vertical: padV),
            child: TextField(
              controller: controller,
              maxLines: lineCount,
              minLines: lineCount,
              textInputAction: TextInputAction.newline,
              inputFormatters: <TextInputFormatter>[
                _MemoLineInputFormatter(maxLines: lineCount),
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
              ),
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 12.s,
                fontWeight: FontWeight.w700,
                height: (lineHeight / 12.s).toDouble(),
                color: const Color(0x80383838),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoLineInputFormatter extends TextInputFormatter {
  final int maxLines;

  const _MemoLineInputFormatter({required this.maxLines});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 줄 수가 maxLines를 초과하면 입력을 막고 이전 상태 유지
    final lines = newValue.text.split('\n');
    if (lines.length > maxLines) {
      return oldValue;
    }
    return newValue;
  }
}

class _TempHumidityBox extends StatelessWidget {
  final TextEditingController tempController;
  final TextEditingController humidityController;

  const _TempHumidityBox({
    required this.tempController,
    required this.humidityController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73.s,
      decoration: BoxDecoration(
        color: const Color(0x0D383838),
        border: Border.all(color: const Color(0x33383838), width: 0.89.s),
        borderRadius: BorderRadius.circular(12.46.s),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('온도', style: _labelStyle()),
                SizedBox(height: 4.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 48.s,
                      child: TextField(
                        controller: tempController,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onTap: () async {
                          final current =
                              int.tryParse(tempController.text.trim()) ?? 30;
                          final initial = current.clamp(0, 50);
                          final picked = await showModalBottomSheet<int>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => _NumberPickerSheet(
                              min: 0,
                              max: 50,
                              initial: initial,
                              unitLabel: '°C',
                              title: '온도 선택',
                            ),
                          );
                          if (picked != null) {
                            tempController.text = picked.toString();
                          }
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: _valueStyle(),
                      ),
                    ),
                    SizedBox(width: 2.s),
                    Text('°C', style: _valueStyle()),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1.s, height: 49.s, color: const Color(0x33383838)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('습도', style: _labelStyle()),
                SizedBox(height: 4.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 48.s,
                      child: TextField(
                        controller: humidityController,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onTap: () async {
                          final current =
                              int.tryParse(humidityController.text.trim()) ??
                              50;
                          final initial = current.clamp(0, 100);
                          final picked = await showModalBottomSheet<int>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => _NumberPickerSheet(
                              min: 0,
                              max: 100,
                              initial: initial,
                              unitLabel: '%',
                              title: '습도 선택',
                            ),
                          );
                          if (picked != null) {
                            humidityController.text = picked.toString();
                          }
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: _valueStyle(),
                      ),
                    ),
                    SizedBox(width: 2.s),
                    Text('%', style: _valueStyle()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 12.s,
    fontWeight: FontWeight.w700,
    color: const Color(0x80383838),
  );

  TextStyle _valueStyle() => TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 19.s,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: const Color(0xFF383838),
  );
}
