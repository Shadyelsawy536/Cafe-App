import 'package:flutter/animation.dart';

/// One place for every animation timing in the app. Change the feel of the
/// whole "premium engine" from here rather than hunting through screens.
class AppDurations {
  static const hero = Duration(milliseconds: 700);
  static const textSwitch = Duration(milliseconds: 350);
  static const priceSwitch = Duration(milliseconds: 300);
  static const addonSelect = Duration(milliseconds: 220);
  static const buttonState = Duration(milliseconds: 300);
  static const receiptCheck = Duration(milliseconds: 900);
  static const screenTransition = Duration(milliseconds: 380);
}

class AppCurves {
  static const hero = Curves.easeOutCubic;
  static const buttonBounce = Curves.easeOutBack;
  static const check = Curves.elasticOut;
  static const screenTransition = Curves.easeInOutCubic;
}
