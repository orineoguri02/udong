import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app-theme.dart';
import '../utils/app-size.dart';

/// 공통 프로필 선택 다이얼로그
///
/// - [labels]: 프로필 이름 리스트
/// - [initialSelectedIndex]: 초기 선택 인덱스
/// - 반환값: 선택된 인덱스(0 이상) 또는 `-1`(추가 선택), `null`(닫기)
typedef ProfileDeleteHandler = Future<bool> Function(int index);

Future<int?> showProfileSelectDialog({
  required BuildContext context,
  required List<String> labels,
  List<String?>? imageUrls,
  int initialSelectedIndex = 0,
  bool enableEdit = false,
  Set<int> nonDeletableIndices = const <int>{},
  ProfileDeleteHandler? onDeleteIndex,
}) {
  return showDialog<int>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    builder: (ctx) => _ProfileSelectDialog(
      labels: labels,
      imageUrls: imageUrls,
      initialSelectedIndex: initialSelectedIndex,
      enableEdit: enableEdit,
      nonDeletableIndices: nonDeletableIndices,
      onDeleteIndex: onDeleteIndex,
    ),
  );
}

class _ProfileSelectDialog extends StatefulWidget {
  final List<String> labels;
  final List<String?>? imageUrls;
  final int initialSelectedIndex;
  final bool enableEdit;
  final Set<int> nonDeletableIndices;
  final ProfileDeleteHandler? onDeleteIndex;

  const _ProfileSelectDialog({
    required this.labels,
    this.imageUrls,
    required this.initialSelectedIndex,
    required this.enableEdit,
    required this.nonDeletableIndices,
    this.onDeleteIndex,
  });

  @override
  State<_ProfileSelectDialog> createState() => _ProfileSelectDialogState();
}

class _ProfileSelectDialogState extends State<_ProfileSelectDialog> {
  late List<String> _labels;
  late List<String?> _imageUrls;
  late int _tempSelectedIndex;
  late Set<int> _nonDeletableIndices;
  bool _isEditMode = false;
  int? _deletingIndex;

  @override
  void initState() {
    super.initState();
    _labels = List<String>.from(widget.labels);
    _imageUrls = widget.imageUrls != null
        ? List<String?>.from(widget.imageUrls!)
        : List<String?>.filled(_labels.length, null);
    if (_imageUrls.length < _labels.length) {
      _imageUrls.addAll(
        List<String?>.filled(_labels.length - _imageUrls.length, null),
      );
    } else if (_imageUrls.length > _labels.length) {
      _imageUrls = _imageUrls.sublist(0, _labels.length);
    }
    _tempSelectedIndex = _labels.isEmpty
        ? 0
        : widget.initialSelectedIndex.clamp(0, _labels.length - 1);
    _nonDeletableIndices = widget.nonDeletableIndices
        .where((index) => index >= 0 && index < _labels.length)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width - 48.s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6.s,
                offset: Offset(0, 2.s),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.s, 18.s, 12.s, 14.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '프로필 선택',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 16.s,
                        fontWeight: FontWeight.w800,
                        color: AppColors.font,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.enableEdit)
                          GestureDetector(
                            onTap: _isEditMode
                                ? null
                                : () => setState(() => _isEditMode = true),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.s,
                                vertical: 4.s,
                              ),
                              child: Text(
                                '편집',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: 13.s,
                                  fontWeight: FontWeight.w700,
                                  color: _isEditMode
                                      ? const Color(0xFFBDBDBD)
                                      : AppColors.font,
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Padding(
                            padding: EdgeInsets.all(4.s),
                            child: Icon(
                              Icons.close,
                              size: 22.s,
                              color: AppColors.font,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.s, 0, 24.s, 16.s),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ProfileRowOnlyCommon(
                    labels: _labels,
                    imageUrls: _imageUrls,
                    selectedIndex: _tempSelectedIndex,
                    isEditMode: _isEditMode,
                    nonDeletableIndices: _nonDeletableIndices,
                    deletingIndex: _deletingIndex,
                    onSelect: (index) {
                      if (_isEditMode) return;
                      setState(() => _tempSelectedIndex = index);
                    },
                    onDelete: _handleDelete,
                    onAdd: _isEditMode
                        ? null
                        : () => Navigator.pop(context, -1),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.s, 0, 20.s, 20.s),
                child: SizedBox(
                  width: double.infinity,
                  height: 44.s,
                  child: ElevatedButton(
                    onPressed: _isEditMode
                        ? () => setState(() => _isEditMode = false)
                        : () => Navigator.pop(context, _tempSelectedIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.main,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.s),
                      ),
                    ),
                    child: Text(
                      _isEditMode ? '완료' : '확인',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 14.s,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(int index) async {
    if (_deletingIndex != null) return;
    if (widget.onDeleteIndex == null) return;
    if (index < 0 || index >= _labels.length) return;

    setState(() => _deletingIndex = index);
    var removed = false;
    try {
      removed = await widget.onDeleteIndex!(index);
    } catch (_) {
      removed = false;
    }
    if (!mounted) return;

    if (!removed || index < 0 || index >= _labels.length) {
      setState(() => _deletingIndex = null);
      return;
    }

    setState(() {
      _labels.removeAt(index);
      _imageUrls.removeAt(index);
      _tempSelectedIndex = _nextSelectedIndexAfterDelete(
        selectedIndex: _tempSelectedIndex,
        deletedIndex: index,
        nextLength: _labels.length,
      );
      _nonDeletableIndices = _reindexIndicesAfterDelete(
        indices: _nonDeletableIndices,
        deletedIndex: index,
        maxLength: _labels.length,
      );
      _deletingIndex = null;
      if (_labels.isEmpty) {
        _isEditMode = false;
      }
    });
  }

  int _nextSelectedIndexAfterDelete({
    required int selectedIndex,
    required int deletedIndex,
    required int nextLength,
  }) {
    if (nextLength <= 0) return 0;
    if (selectedIndex > deletedIndex) return selectedIndex - 1;
    if (selectedIndex == deletedIndex) {
      return deletedIndex.clamp(0, nextLength - 1);
    }
    return selectedIndex.clamp(0, nextLength - 1);
  }

  Set<int> _reindexIndicesAfterDelete({
    required Set<int> indices,
    required int deletedIndex,
    required int maxLength,
  }) {
    final next = <int>{};
    for (final value in indices) {
      if (value == deletedIndex) continue;
      final reindexed = value > deletedIndex ? value - 1 : value;
      if (reindexed >= 0 && reindexed < maxLength) {
        next.add(reindexed);
      }
    }
    return next;
  }
}

class _ProfileRowOnlyCommon extends StatelessWidget {
  final List<String> labels;
  final List<String?>? imageUrls;
  final int selectedIndex;
  final bool isEditMode;
  final Set<int> nonDeletableIndices;
  final int? deletingIndex;
  final ValueChanged<int>? onSelect;
  final ValueChanged<int>? onDelete;
  final VoidCallback? onAdd;

  const _ProfileRowOnlyCommon({
    required this.labels,
    this.imageUrls,
    required this.selectedIndex,
    required this.isEditMode,
    required this.nonDeletableIndices,
    this.deletingIndex,
    this.onSelect,
    this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Wrap(
      spacing: 18.s,
      runSpacing: 10.s,
      alignment: WrapAlignment.start,
      children: [
        ...labels.asMap().entries.map((e) {
          final imageUrl = (imageUrls != null && e.key < imageUrls!.length)
              ? imageUrls![e.key]
              : null;
          final canDelete =
              isEditMode &&
              onDelete != null &&
              !nonDeletableIndices.contains(e.key);
          return GestureDetector(
            onTap: isEditMode ? null : () => onSelect?.call(e.key),
            child: SizedBox(
              width: 84.s,
              child: _SmallProfileItemCommon(
                label: e.value.isNotEmpty ? e.value : '프로필 ${e.key + 1}',
                imageUrl: imageUrl,
                isSelected: e.key == selectedIndex,
                canDelete: canDelete,
                isDeleting: deletingIndex == e.key,
                onDelete: canDelete ? () => onDelete?.call(e.key) : null,
              ),
            ),
          );
        }),
        if (!isEditMode)
          GestureDetector(
            onTap: onAdd,
            child: SizedBox(width: 84.s, child: const _AddProfileItemCommon()),
          ),
      ],
    );
  }
}

class _SmallProfileItemCommon extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  const _SmallProfileItemCommon({
    required this.label,
    this.imageUrl,
    required this.isSelected,
    required this.canDelete,
    this.isDeleting = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 72.s,
              height: 72.s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: AppColors.main, width: 2.5.s)
                    : null,
              ),
              child: ClipOval(child: _buildProfileImage(context)),
            ),
            if (isSelected)
              Positioned(
                right: -2.s,
                bottom: -2.s,
                child: Container(
                  width: 22.s,
                  height: 22.s,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5.s),
                  ),
                  child: Icon(Icons.check, size: 14.s, color: Colors.black),
                ),
              ),
            if (canDelete)
              Positioned(
                right: -2.s,
                top: -2.s,
                child: GestureDetector(
                  onTap: isDeleting ? null : onDelete,
                  child: Container(
                    width: 22.s,
                    height: 22.s,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF05555),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5.s),
                    ),
                    child: Center(
                      child: isDeleting
                          ? SizedBox(
                              width: 11.s,
                              height: 11.s,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8.s,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.close, size: 13.s, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.s),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 11.s,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            color: isSelected ? AppColors.main : AppColors.font,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (72.s * devicePixelRatio).round();
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Image.asset(
        'assets/icons/profile-placeholder.webp',
        width: 72.s,
        height: 72.s,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    }

    final normalizedPath = _normalizeLocalPath(imageUrl!);
    if (normalizedPath != null) {
      return Image.file(
        File(normalizedPath),
        width: 72.s,
        height: 72.s,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/icons/profile-placeholder.webp',
          width: 72.s,
          height: 72.s,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 72.s,
      height: 72.s,
      fit: BoxFit.cover,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => Image.asset(
        'assets/icons/profile-placeholder.webp',
        width: 72.s,
        height: 72.s,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      ),
      errorWidget: (_, __, ___) => Image.asset(
        'assets/icons/profile-placeholder.webp',
        width: 72.s,
        height: 72.s,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      ),
    );
  }

  String? _normalizeLocalPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return null;
    }
    if (value.startsWith('file://')) {
      return value.replaceFirst('file://', '');
    }
    if (value.startsWith('/')) {
      return value;
    }
    return null;
  }
}

class _AddProfileItemCommon extends StatelessWidget {
  const _AddProfileItemCommon();

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72.s,
          height: 72.s,
          child: Center(
            child: Image.asset(
              'assets/images/mypage/addicon.webp',
              width: 72.s,
              height: 72.s,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 8.s),
        Text(
          '추가',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 11.s,
            fontWeight: FontWeight.w500,
            color: AppColors.font,
          ),
        ),
      ],
    );
  }
}
