import 'package:flutter/material.dart';

import '../utils/app-size.dart';

/// 서브 페이지용: 뒤로가기 + 가운데 타이틀
class PageTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const PageTitleAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.s + 1.s);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return AppBar(
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
        title,
        style: TextStyle(
          color: const Color(0xFF383838),
          fontSize: 18.9.s,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.s),
        child: Divider(
          height: 1.s,
          thickness: 1.s,
          color: const Color(0xFFE0E0E0),
        ),
      ),
    );
  }
}

