/// 이용약관 목록 페이지
///
/// - 역할: 이용약관 항목 목록 표시, 각 항목 클릭 시 상세 페이지로 이동

import 'package:flutter/material.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/pages/my-page/terms-detail-page.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const List<_TermsItem> _items = [
    _TermsItem(
      title: '서비스 이용 약관',
      content: '''
우동: 우리들의 반려동물

시행일: 2026-02-28

제1조(목적)

본 약관은 여정(이하 "운영자")이 제공하는 모바일 애플리케이션 "우동: 우리들의 반려동물"(이하 "서비스")의 이용과 관련하여 운영자와 이용자 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조(정의)

"서비스"란 운영자가 제공하는 모바일 애플리케이션 및 관련 기능 일체를 말합니다.

"이용자"란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

"회원"이란 카카오/구글/애플 로그인 등으로 계정을 생성(연동)하여 서비스를 이용하는 자를 말합니다.

"콘텐츠"란 서비스 내에서 제공되거나 생성되는 정보, 텍스트, 이미지, 기록, 데이터 등 일체를 말합니다.

제3조(약관의 효력 및 변경)

이용자가 서비스 화면에서 약관에 동의하거나 서비스를 다운로드·이용하는 경우 본 약관에 동의한 것으로 봅니다.

운영자는 관련 법령을 위반하지 않는 범위에서 약관을 변경할 수 있으며, 변경 시 적용일 및 변경 사유를 서비스 내 공지 또는 기타 적절한 방법으로 안내합니다.

이용자가 변경 약관의 적용일 이후에도 서비스를 계속 이용하는 경우 변경 약관에 동의한 것으로 봅니다.

제4조(서비스의 내용 및 유의사항)

서비스는 특수동물(예: 파충류, 양서류, 조류, 설치류 등)의 관리 및 헬스케어를 돕기 위한 기능을 제공합니다(예: 기록/일정/알림, 정보 제공, 추천 기능 등).

서비스에서 제공되는 정보 및 추천 기능은 참고용이며, 수의학적 진단 또는 치료를 대체하지 않습니다.

응급 상황이거나 의료적 판단이 필요한 경우 이용자는 전문가(수의사 등)와 상담해야 하며, 이를 따르지 않아 발생한 불이익에 대해 운영자는 법령상 허용되는 범위 내에서 책임을 제한할 수 있습니다.

제5조(회원가입 및 로그인)

서비스는 아래 소셜 로그인 방식만을 지원합니다.

Google 로그인

이용자는 본인 명의의 계정으로 서비스를 이용해야 하며, 타인의 계정 도용 또는 부정 사용을 해서는 안 됩니다.

운영자는 보안 및 운영상 필요에 따라 특정 계정 또는 이용자의 서비스 이용을 제한할 수 있습니다.

제6조(서비스 제공 및 변경, 중단)

운영자는 서비스의 품질 향상, 기능 개선, 운영상 필요에 따라 서비스의 전부 또는 일부를 변경할 수 있습니다.

운영자는 다음 사유가 있는 경우 서비스 제공을 일시적으로 중단할 수 있습니다.

1) 설비 점검/교체/고장 등 유지보수
2) 통신 장애/제3자 서비스 장애
3) 천재지변 등 불가항력

가능한 경우 사전에 안내하나, 긴급한 사유가 있는 경우 사후 안내할 수 있습니다.

제7조(광고의 게재)

서비스는 현재 무료로 제공되며, 운영자는 서비스 화면에 배너 등 광고를 게재할 수 있습니다(추후 도입 포함).

광고의 내용/품질/신뢰성 및 광고주와 이용자 간 거래에 대해서는 광고주가 책임을 부담하며, 운영자는 법령상 허용되는 범위 내에서 책임을 제한할 수 있습니다.

제8조(이용자의 의무 및 금지행위)

이용자는 관련 법령, 본 약관, 운영자의 안내 및 공지사항을 준수해야 합니다.

이용자는 다음 행위를 하여서는 안 됩니다.

1) 권리침해(저작권/상표권 등)
2) 정상 운영 방해(버그 악용/과도 트래픽 등)
3) 도용
4) 불법·음란·혐오·차별·폭력 등 위법/부적절 정보 게시
5) 역설계/복제/배포/파생서비스 제작
6) 기타 부적절 행위

제9조(계정 및 기기 보안)

이용자는 본인 기기 및 로그인 수단 관리 책임이 있으며, 계정 정보를 제3자에게 제공/공유/양도할 수 없습니다.

운영자는 보안/안정성을 위해 루팅/탈옥 기기에서의 이용을 제한할 수 있습니다.

제10조(지식재산권)

서비스 및 구성 요소의 지식재산권은 운영자 또는 정당한 권리자에게 귀속됩니다.

이용자는 운영자 사전 동의 없이 복제/수정/배포/판매/역설계/2차적 저작물 작성 등을 할 수 없습니다.

제11조(제3자 서비스)

서비스는 원활한 제공을 위해 제3자 서비스(예: Google Play Services, Google Analytics for Firebase, Firebase Crashlytics 등)를 이용할 수 있으며, 해당 제공자의 정책에 따릅니다.

제12조(이용 제한 및 탈퇴)

이용자가 약관/법령을 위반하는 경우 운영자는 경고, 게시물 삭제, 이용 제한, 계정 정지 또는 탈퇴 처리 등을 할 수 있습니다.

회원 탈퇴는 서비스 내 제공되는 기능을 통해 언제든지 신청할 수 있습니다.

탈퇴 및 데이터 처리에 관한 사항은 개인정보 관련 문서에 따릅니다.

제13조(책임 제한)

천재지변/통신 장애/점검/제3자 서비스 장애 등 통제 불가 사유로 서비스 제공이 불가한 경우 책임을 부담하지 않습니다.

데이터 통신 요금(데이터/로밍 등)은 이용자 부담입니다.

이용자가 서비스 정보/자료를 신뢰하여 발생한 손해에 대해 법령상 허용되는 범위 내에서 책임을 제한할 수 있습니다.

제14조(준거법 및 관할)

대한민국 법령을 준거법으로 합니다.

분쟁 발생 시 민사소송법 등 관련 법령이 정한 절차에 따르며, 관할 법원은 운영자의 주소지 관할 법원으로 합니다.

제15조(문의)

이메일: yeojungofficial@gmail.com

운영자: 여정
''',
    ),
    _TermsItem(
      title: '개인정보 수집 및 이용',
      content: '''
우동: 우리들의 반려동물

시행일: 2026-02-28

여정(이하 "운영자")은 「개인정보 보호법」 등 관련 법령을 준수하며, 이용자의 개인정보를 안전하게 보호하기 위해 본 내용을 안내합니다. 본 문서는 모바일 애플리케이션 "우동: 우리들의 반려동물"(이하 "서비스")에 적용됩니다.

1. 수집하는 개인정보 항목

(1) 이용자가 직접 제공하는 정보(회원가입/프로필)
서비스는 Google 소셜 로그인을 지원하며, 이 과정에서 아래 정보가 수집·처리될 수 있습니다.

이메일(필수) / 이름(필수) / 생년월일(필수) / 성별(필수)

소셜 로그인 식별 정보(예: 고유 식별자, 인증 토큰 등)
※ 운영자는 소셜 로그인 제공자로부터 이용자의 비밀번호를 수집하거나 저장하지 않습니다.

(2) 서비스 이용 과정에서 자동 수집되는 정보

IP 주소, 방문/이용 기록, 접속 일시, 앱 내 활동 기록, 오류 기록

기기정보(운영체제(OS), 기기 식별 정보 일부, 앱 버전 등)

2. 수집·이용 목적

회원가입 및 계정 관리(본인 식별, 중복 가입 방지, 계정 유지/관리)

프로필 구성 및 서비스 제공(기본 프로필 제공, 서비스 운영)

고객문의 대응 및 공지 전달(필수 고지, 문의 처리)

서비스 안정성 및 품질 개선(이용 기록 분석, 오류/장애 대응, 보안 강화)

3. 보유 및 이용기간

회원 정보(이메일/이름/생년월일/성별): 회원 탈퇴 시까지 보관

탈퇴 후에도 분쟁 대응/부정 이용 방지 등을 위해 합리적인 기간 동안 최소 정보가 보관될 수 있습니다.

관련 법령에 따라 보관이 필요한 경우, 해당 법령에서 정한 기간 동안 보관합니다.

4. 이용자의 권리 및 행사 방법

이용자는 언제든지 개인정보 열람/정정/삭제/처리정지 요청 및 회원 탈퇴를 통한 처리 중단을 요청할 수 있습니다.
요청은 아래 문의처로 접수할 수 있으며, 운영자는 합리적인 기간 내에 처리합니다.

5. 파기 절차 및 방법

보유기간 경과 또는 목적 달성 후 지체 없이 파기합니다.

전자적 파일: 복구 불가능한 방법으로 삭제

출력물: 분쇄 또는 소각

6. 아동의 개인정보

서비스는 만 13세 미만 아동을 대상으로 하지 않으며, 만 13세 미만 아동의 개인정보를 고의로 수집하지 않습니다. 인지 시 즉시 삭제 및 필요한 조치를 합니다.

7. 안전성 확보 조치

접근 권한 관리, 내부 관리 절차 운영, 보안 업데이트 및 취약점 대응, 접근 통제 등 보호조치를 시행합니다.

8. 변경 및 문의

중요 변경 시 서비스 내 공지 또는 별도 안내로 고지합니다.

이메일: yeojungofficial@gmail.com

운영자: 여정
''',
    ),
    _TermsItem(
      title: '개인정보 제3자 제공 및 처리위탁',
      content: '''
우동: 우리들의 반려동물

시행일: 2026-02-28

1. 개인정보의 제3자 제공

운영자는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.
다만, 법령에 근거가 있거나 수사기관의 적법한 절차에 따른 요청이 있는 경우 제공될 수 있습니다.

2. 개인정보 처리의 위탁 및 제3자 서비스 이용

운영자는 서비스 운영 및 안정성 확보를 위해 아래와 같은 제3자 서비스를 이용할 수 있으며, 이 과정에서 일부 정보(기기/이용 기록 등)가 처리될 수 있습니다. 각 서비스는 자체 개인정보처리방침에 따라 정보를 처리합니다.

Google Play Services

Google Analytics for Firebase

Firebase Crashlytics

3. (추후) 광고 도입 시

서비스는 현재 무료로 제공되며 추후 배너 광고가 도입될 수 있습니다. 광고 제공 및 성과 측정을 위해 광고 사업자(예: Google AdMob 등)를 사용할 수 있으며, 이 과정에서 아래 정보가 처리될 수 있습니다.

광고 노출/클릭 등 광고 상호작용 정보

IP 주소, 기기 정보(OS, 앱 버전 등)

개인화 광고 적용 시 광고 식별자(Advertising ID) 등 기기에서 제공되는 식별 정보
이용자는 기기 설정을 통해 광고 식별자 재설정/제한 등 맞춤형 광고 노출을 조정할 수 있습니다.

4. 문의

이메일: yeojungofficial@gmail.com

운영자: 여정
''',
    ),
    _TermsItem(
      title: '위치정보 수집 및 이동 정보 관리',
      content: '''
우동: 우리들의 반려동물

시행일: 2026-02-28

1. 위치정보 수집·이용 목적

이용자가 권한을 허용한 경우, 현재 위치정보를 이용하여 "가까운 거리순 추천" 등 위치 기반 기능을 제공합니다.

2. 수집 범위 및 방식

운영체제(OS)에서 제공되는 범위 내에서 위치정보가 수집·이용될 수 있습니다(정확/대략).

이용자는 기기 설정에서 위치 권한을 언제든지 허용/거부/변경할 수 있습니다.

3. 보관 및 파기(기본 정책)

위치 기반 기능 제공을 위해 일시적으로 처리하며, 원칙적으로 서비스는 위치정보를 저장하지 않습니다.

(만약 추후 저장 기능이 생기거나 보관이 필요해지는 경우) 보관 항목/기간/파기 방법을 사전 고지하고 문서를 업데이트합니다.

4. 문의

이메일: yeojungofficial@gmail.com

운영자: 여정
''',
    ),
    _TermsItem(
      title: '마케팅 정보 수집',
      content: '''
우동: 우리들의 반려동물

시행일: 2026-02-28

1. 현재 운영 방식

운영자는 현재 마케팅 목적의 개인정보 수집·이용 및 광고성 정보(이메일/문자/푸시 등) 전송을 운영하지 않습니다.

2. 추후 도입 시 안내

추후 이벤트/혜택 안내 등 광고성 정보 전송 기능을 도입하는 경우, 관련 법령에 따라 사전 고지하고, 필요한 경우 별도 동의(선택)를 받으며, 이용자는 언제든지 수신 동의를 철회할 수 있습니다.

3. 문의

이메일: yeojungofficial@gmail.com

운영자: 여정
''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/back-icon.webp',
            width: 25.s,
            height: 35.s,
            fit: BoxFit.contain,
          ),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          '이용약관',
          style: TextStyle(
            color: const Color(0xFF383838),
            fontFamily: AppFonts.family,
            fontSize: 18.9.s,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(15.s, 14.s, 15.s, 35.s),
        child: Column(
          children: List.generate(_items.length * 2 - 1, (index) {
            if (index.isOdd) return SizedBox(height: 15.s);
            final item = _items[index ~/ 2];
            return _TermsTile(item: item);
          }),
        ),
      ),
    );
  }
}

class _TermsItem {
  final String title;
  final String content;

  const _TermsItem({required this.title, required this.content});
}

class _TermsTile extends StatelessWidget {
  final _TermsItem item;

  const _TermsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.644.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3.s,
            spreadRadius: 0.198.s,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.644.s),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TermsDetailPage(
                  title: item.title,
                  content: item.content,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.644.s),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.s, vertical: 16.s),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: AppColors.font,
                      fontFamily: AppFonts.family,
                      fontSize: 15.8.s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/icons/next-icon.webp',
                  width: 8.s,
                  height: 14.s,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
