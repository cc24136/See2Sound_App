import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static EdgeInsets pagePadding(double width) {
    if (width < 600) return const EdgeInsets.all(md);
    if (width < 1000) return const EdgeInsets.all(lg);
    return const EdgeInsets.fromLTRB(xl, xxl, xl, xl);
  }
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 18;
  static const BorderRadius card = BorderRadius.all(Radius.circular(large));
  static const BorderRadius control = BorderRadius.all(Radius.circular(medium));
}

abstract final class AppDurations {
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 180);

  static Duration adaptive(bool reduceMotion) {
    return reduceMotion ? Duration.zero : standard;
  }
}

abstract final class AppBreakpoints {
  static const double compact = 720;
  static const double sidebarCompact = 980;
  static const double wide = 1200;
}

abstract final class AppTypography {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );
  static const TextStyle pageSubtitle = TextStyle(fontSize: 17, height: 1.45);
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle body = TextStyle(fontSize: 15, height: 1.45);
  static const TextStyle label = TextStyle(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
}
