import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';

class OutlinePillButton extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const OutlinePillButton({
    super.key,
    required this.label,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.s),
        border: Border.all(color: AppColors.main, width: 1.s),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 11.s,
          fontWeight: FontWeight.w800,
          color: AppColors.main,
        ),
      ),
    );
  }
}

class PetLabeledTextField extends StatefulWidget {
  final String label;
  final String? initialText;
  final String? hintText;

  /// 외부에서 값을 읽을 때 사용. 제공 시 내부 controller를 만들지 않음.
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  const PetLabeledTextField({
    super.key,
    required this.label,
    this.initialText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.maxLength,
  });

  @override
  State<PetLabeledTextField> createState() => _PetLabeledTextFieldState();
}

class _PetLabeledTextFieldState extends State<PetLabeledTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool get _useExternalController => widget.controller != null;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    _controller =
        widget.controller ??
        TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!_useExternalController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 13.s),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13.s,
              fontWeight: FontWeight.w700,
              color: AppColors.font,
            ),
          ),
        ),
        SizedBox(height: 8.s),
        Container(
          width: 225.s,
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
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            inputFormatters: widget.maxLength != null
                ? <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(widget.maxLength),
                  ]
                : null,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13.s,
                fontWeight: FontWeight.w500,
                color: AppColors.fontMuted,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.s,
                vertical: 8.s,
              ),
              filled: true,
              fillColor: Colors.white,
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(23.397.s),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(23.397.s),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13.s,
              fontWeight: FontWeight.w500,
              color: AppColors.font,
            ),
            cursorColor: AppColors.main,
          ),
        ),
      ],
    );
  }
}

class PetCompactLabeledTextField extends StatefulWidget {
  final String label;
  final String? initialText;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool showArrow;
  final double? width;

  const PetCompactLabeledTextField({
    super.key,
    required this.label,
    this.initialText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.showArrow = false,
    this.width,
  });

  @override
  State<PetCompactLabeledTextField> createState() =>
      _PetCompactLabeledTextFieldState();
}

class _PetCompactLabeledTextFieldState
    extends State<PetCompactLabeledTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool get _useExternalController => widget.controller != null;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    _controller =
        widget.controller ??
        TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!_useExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 13.s),
          child: Text(
            widget.label,
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
          onTap: widget.onTap,
          child: Container(
            width: widget.width ?? 156.s,
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
            child: IgnorePointer(
              ignoring: widget.onTap != null,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.onTap != null,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 13.s,
                    fontWeight: FontWeight.w500,
                    color: AppColors.fontMuted,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.s,
                    vertical: 6.s,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(23.397.s),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(23.397.s),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: widget.showArrow
                      ? Icon(
                          Icons.chevron_right,
                          size: 18.s,
                          color: AppColors.fontLight,
                        )
                      : null,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 28.s,
                    minHeight: 0,
                    maxHeight: 28.s,
                  ),
                ),
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13.s,
                  fontWeight: FontWeight.w500,
                  color: AppColors.font,
                ),
                cursorColor: AppColors.main,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PetGenderSelector extends StatefulWidget {
  final bool initialIsMale;
  final void Function(bool isMale)? onChanged;

  const PetGenderSelector({
    super.key,
    required this.initialIsMale,
    this.onChanged,
  });

  @override
  State<PetGenderSelector> createState() => _PetGenderSelectorState();
}

class _PetGenderSelectorState extends State<PetGenderSelector> {
  late bool _isMaleSelected;

  @override
  void initState() {
    super.initState();
    _isMaleSelected = widget.initialIsMale;
  }

  @override
  void didUpdateWidget(covariant PetGenderSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsMale != widget.initialIsMale) {
      _isMaleSelected = widget.initialIsMale;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return SizedBox(
      width: 90.268.s,
      height: 28.096.s,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23.397.s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2.865.s,
              spreadRadius: 0.18.s,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isMaleSelected = true);
                  widget.onChanged?.call(true);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _isMaleSelected
                        ? Colors.white
                        : const Color(0xFFD7D7D7),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(23.397.s),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/icons/zender1.webp',
                    width: 10.s,
                    height: 20.s,
                    fit: BoxFit.contain,
                    color: _isMaleSelected ? null : const Color(0xFF878787),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isMaleSelected = false);
                  widget.onChanged?.call(false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _isMaleSelected
                        ? const Color(0xFFD7D7D7)
                        : Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(23.397.s),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/icons/zender.webp',
                    width: 10.s,
                    height: 20.s,
                    fit: BoxFit.contain,
                    color: _isMaleSelected ? const Color(0xFF878787) : null,
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
