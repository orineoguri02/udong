import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../features/home/models/pet-profile.dart';
import 'pet-form-widgets.dart';

class ProfileSettingsSection extends StatelessWidget {
  final VoidCallback onShowDialog;
  final PetProfile profile;
  final TextEditingController nameController;
  final ValueChanged<bool> onGenderChanged;
  final ValueChanged<String> onImagePicked;

  const ProfileSettingsSection({
    super.key,
    required this.onShowDialog,
    required this.profile,
    required this.nameController,
    required this.onGenderChanged,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.s),
            child: GestureDetector(
              onTap: onShowDialog,
              child: OutlinePillButton(
                label: '반려가족 설정',
                padding: EdgeInsets.symmetric(horizontal: 9.s, vertical: 6.s),
              ),
            ),
          ),
        ),
        PetMainProfileSection(
          imageUrl: profile.imageUrl,
          onImagePicked: onImagePicked,
        ),
        SizedBox(height: 20.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 17.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PetLabeledTextField(
                label: '반려가족 이름',
                hintText: '반려가족 이름을 설정해주세요',
                controller: nameController,
                maxLength: 20,
              ),
              SizedBox(height: 22.s),
              Padding(
                padding: EdgeInsets.only(left: 13.s),
                child: Text(
                  '성별',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 13.s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.font,
                  ),
                ),
              ),
              SizedBox(height: 8.s),
              PetGenderSelector(
                initialIsMale: profile.isMale,
                onChanged: onGenderChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PetMainProfileSection extends StatefulWidget {
  final void Function(String path)? onImagePicked;
  final String? imageUrl;

  const PetMainProfileSection({super.key, this.onImagePicked, this.imageUrl});

  @override
  State<PetMainProfileSection> createState() => _PetMainProfileSectionState();
}

class _PetMainProfileSectionState extends State<PetMainProfileSection> {
  String? _pickedPath;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedPath = picked.path);
      widget.onImagePicked?.call(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: SizedBox(
          width: 125.s,
          height: 125.s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                right: 0,
                child: ClipOval(child: _buildProfileImage(context)),
              ),
              Positioned(
                top: -5.s,
                left: -25.s,
                child: Image.asset(
                  'assets/images/mypage/add_profile.webp',
                  width: 60.s,
                  height: 60.s,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (125.s * devicePixelRatio).round();
    final pickedPath = _pickedPath;
    if (pickedPath != null) {
      // 웹은 image_picker가 blob: URL을 주므로 network 이미지로 표시한다.
      if (kIsWeb) {
        return Image.network(
          pickedPath,
          width: 125.s,
          height: 125.s,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
        );
      }
      return Image.file(
        File(pickedPath),
        width: 125.s,
        height: 125.s,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
    }

    final raw = widget.imageUrl?.trim();
    if (raw != null && raw.isNotEmpty) {
      final normalizedPath = _normalizeLocalPath(raw);
      if (normalizedPath != null) {
        return Image.file(
          File(normalizedPath),
          width: 125.s,
          height: 125.s,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, __, ___) => _placeholderImage(),
        );
      }
      return CachedNetworkImage(
        imageUrl: raw,
        width: 125.s,
        height: 125.s,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => _placeholderImage(),
        errorWidget: (_, __, ___) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Image.asset(
      'assets/icons/profile-placeholder.webp',
      width: 125.s,
      height: 125.s,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }

  String? _normalizeLocalPath(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return null;
    if (raw.startsWith('file://')) return raw.replaceFirst('file://', '');
    if (raw.startsWith('/')) return raw;
    return null;
  }
}
