import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppBorders {
  const AppBorders._();

  static BorderSide dark = const BorderSide(
    color: AppColors.darkBorder,
    width: 1,
  );

  static BorderSide darkStrong = const BorderSide(
    color: AppColors.darkBorderStrong,
    width: 1,
  );

  static BorderSide light = const BorderSide(
    color: AppColors.lightBorder,
    width: 1,
  );

  static BorderSide lightStrong = const BorderSide(
    color: AppColors.lightBorderStrong,
    width: 1,
  );
}