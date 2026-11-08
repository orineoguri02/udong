/// 피그마 px 값을 기기 비율에 맞게 스케일링하는 유틸.
import 'package:flutter/widgets.dart';

abstract final class SizeConfig {
  static const double baseWidth = 393; // iPhone 16 기준

  static late double _screenWidth;
  static late double _scale;

  static bool _initialized = false;

  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _scale = _screenWidth / baseWidth;
    _initialized = true;
  }

  static double scale(double figmaValue) {
    if (!_initialized) {
      return figmaValue;
    }
    return figmaValue * _scale;
  }
}

/// 숫자에 직접 `.s` 를 붙여서 쓰기 위한 익스텐션
extension SizeExtension on num {
  /// 피그마 px → 플러터 dp (가로 기준 스케일)
  double get s => SizeConfig.scale(toDouble());
}

