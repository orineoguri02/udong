import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/features/hospital/models/hospital.dart';
import 'package:udon/pages/hospital/widgets/directions-nav-section.dart';

/// [raw]이 http(s) 웹 URL로 해석되면 Uri, 아니면 null.
Uri? _homepageLaunchUri(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(t)
      ? t
      : 'https://$t';
  final u = Uri.tryParse(withScheme);
  if (u == null || !u.hasScheme) return null;
  if (u.scheme != 'http' && u.scheme != 'https') return null;
  if (u.host.isEmpty) return null;
  return u;
}

class HospitalDetailContent extends StatefulWidget {
  const HospitalDetailContent({
    super.key,
    required this.hospital,
    this.initialTab = 0,
  });

  final Hospital hospital;
  final int initialTab;

  @override
  State<HospitalDetailContent> createState() => _HospitalDetailContentState();
}

class _HospitalDetailContentState extends State<HospitalDetailContent> {
  late int _selectedTab;

  static const List<String> _weekdays = <String>[
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab == 1 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final hospital = widget.hospital;
    final isOpen = hospital.isOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.s),
        Padding(
          padding: EdgeInsets.only(left: 40.46.s, right: 20.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  hospital.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w800,
                    fontSize: 25.2886.s,
                    height: 29 / 25.2886,
                    color: AppColors.font,
                  ),
                ),
              ),
              SizedBox(width: 8.s),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.77.s,
                  vertical: 3.77.s,
                ),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.main : AppColors.fontLight,
                  borderRadius: BorderRadius.circular(16.7705.s),
                ),
                child: Text(
                  isOpen ? '진료중' : '휴진',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.0762.s,
                    height: 11 / 10.0762,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.s),
        Padding(
          padding: EdgeInsets.only(left: 40.46.s, right: 20.s),
          child: Column(
            children: [
              _HospitalDetailInfoRow(
                icon: Icons.location_on_outlined,
                text: hospital.address,
              ),
              SizedBox(height: 6.s),
              _HospitalDetailInfoRow(
                icon: Icons.call_outlined,
                text: hospital.phone,
              ),
              SizedBox(height: 6.s),
              _HospitalDetailInfoRow(
                icon: Icons.schedule,
                text: hospital.operatingHours,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 26.s),
          child: Container(
            height: 32.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.s),
              border: Border.all(color: AppColors.main, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.s),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        color: _selectedTab == 0
                            ? AppColors.main
                            : Colors.white,
                        alignment: Alignment.center,
                        child: Text(
                          '병원 소개',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.s,
                            height: 14 / 12,
                            color: _selectedTab == 0
                                ? Colors.white
                                : AppColors.main,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppColors.main),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        color: _selectedTab == 1
                            ? AppColors.main
                            : Colors.white,
                        alignment: Alignment.center,
                        child: Text(
                          '찾아가기',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.s,
                            height: 14 / 12,
                            color: _selectedTab == 1
                                ? Colors.white
                                : AppColors.main,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.s),
        IndexedStack(
          index: _selectedTab,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.s),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.s, vertical: 20.s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.8685.s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3.s,
                      spreadRadius: 0.2.s,
                    ),
                  ],
                ),
                child: _buildIntroContent(hospital),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 36.s),
              child: _buildDirectionsContent(hospital),
            ),
          ],
        ),
        SizedBox(height: 40.s),
      ],
    );
  }

  Widget _buildDirectionsContent(Hospital hospital) {
    return Column(
      children: [
        SizedBox(height: 16.s),
        DirectionsNavSection(hospital: hospital),
        SizedBox(height: 20.s),
      ],
    );
  }

  Widget _buildIntroContent(Hospital hospital) {
    final animalLabels = hospital.animals.isNotEmpty
        ? hospital.animals
        : const <String>['정보 없음'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_outlined, size: 20.s, color: AppColors.main),
            SizedBox(width: 8.s),
            Text(
              '요일별 진료 시간',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w800,
                fontSize: 16.s,
                height: 1.5,
                color: AppColors.font,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.s),
        ..._weekdays.map((day) {
          final time = hospital.weekdaySchedule[day];
          return Padding(
            padding: EdgeInsets.only(bottom: 8.s),
            child: _HospitalScheduleRow(day: day, time: time),
          );
        }),
        SizedBox(height: 24.s),
        Row(
          children: [
            Image.asset(
              'assets/icons/icon-stethoscope.webp',
              width: 20.s,
              height: 20.s,
              color: AppColors.main,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8.s),
            Text(
              '진료 가능 동물',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w800,
                fontSize: 16.s,
                height: 1.5,
                color: AppColors.font,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.s),
        Wrap(
          spacing: 8.s,
          runSpacing: 8.s,
          children: animalLabels
              .map((label) => _HospitalAnimalChip(label: label))
              .toList(),
        ),
        if (hospital.extraInfo.isNotEmpty) ...[
          SizedBox(height: 24.s),
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.s, color: AppColors.main),
              SizedBox(width: 8.s),
              Text(
                '추가 정보',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.s,
                  height: 1.5,
                  color: AppColors.font,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.s),
          ...hospital.extraInfo.map(
            (info) => Padding(
              padding: EdgeInsets.only(bottom: 8.s),
              child: _HospitalExtraInfoRow(info: info),
            ),
          ),
        ],
      ],
    );
  }
}

class _HospitalDetailInfoRow extends StatelessWidget {
  const _HospitalDetailInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Row(
      children: [
        Icon(icon, size: 16.s, color: AppColors.main),
        SizedBox(width: 10.s),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w400,
              fontSize: 13.s,
              height: 15 / 13,
              color: AppColors.font,
            ),
          ),
        ),
      ],
    );
  }
}

class _HospitalScheduleRow extends StatelessWidget {
  const _HospitalScheduleRow({required this.day, this.time});

  final String day;
  final String? time;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isHoliday = time == null;

    return Container(
      height: 37.s,
      padding: EdgeInsets.symmetric(horizontal: 12.s),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10.s),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w400,
              fontSize: 14.s,
              height: 1.5,
              color: AppColors.font,
            ),
          ),
          Text(
            isHoliday ? '휴진' : (time ?? ''),
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w400,
              fontSize: 14.s,
              height: 1.5,
              color: isHoliday ? const Color(0xFFFF4545) : AppColors.font,
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalAnimalChip extends StatelessWidget {
  const _HospitalAnimalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.s, vertical: 5.s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5ED),
        borderRadius: BorderRadius.circular(9999.s),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w400,
          fontSize: 13.s,
          height: 20 / 13,
          color: AppColors.main,
        ),
      ),
    );
  }
}

class _HospitalExtraInfoRow extends StatelessWidget {
  const _HospitalExtraInfoRow({required this.info});

  final HospitalExtraInfo info;

  static const String _homepageLabel = '홈페이지';

  Future<void> _openHomepage(BuildContext context) async {
    final uri = _homepageLaunchUri(info.badge);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('열 수 없는 주소입니다.')),
        );
      }
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isHomepage = info.label == _homepageLabel;
    final uri = isHomepage ? _homepageLaunchUri(info.badge) : null;
    final canOpen = isHomepage && uri != null;

    final row = Container(
      height: 42.s,
      padding: EdgeInsets.symmetric(horizontal: 12.s),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10.s),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            info.label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w400,
              fontSize: 14.s,
              height: 1.5,
              color: AppColors.font,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.s, vertical: 4.s),
            decoration: BoxDecoration(
              color: AppColors.main,
              borderRadius: BorderRadius.circular(9999.s),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150.s),
              child: Text(
                info.badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.s,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!canOpen) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openHomepage(context),
        borderRadius: BorderRadius.circular(10.s),
        child: row,
      ),
    );
  }
}
