import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen utility helpers for responsive design
class ScreenUtils {
  /// Get screen width
  static double get screenWidth => 1.sw;

  /// Get screen height
  static double get screenHeight => 1.sh;

  /// Get status bar height
  static double get statusBarHeight => ScreenUtil().statusBarHeight;

  /// Get bottom bar height
  static double get bottomBarHeight => ScreenUtil().bottomBarHeight;

  /// Get responsive width using ScreenUtil
  static double width(double width) => ScreenUtil().setWidth(width);

  /// Get responsive height using ScreenUtil
  static double height(double height) => ScreenUtil().setHeight(height);

  /// Get responsive font size using ScreenUtil
  static double fontSize(double size) => ScreenUtil().setSp(size);

  /// Get responsive radius using ScreenUtil
  static double radius(double radius) => ScreenUtil().radius(radius);

  /// Get responsive padding/margin using ScreenUtil
  static double spacing(double spacing) => ScreenUtil().setWidth(spacing);

  /// Check if device is tablet
  static bool get isTablet => ScreenUtil().screenWidth > 600;

  /// Check if device is phone
  static bool get isPhone => !isTablet;

  /// Get device pixel ratio
  static double get pixelRatio => ScreenUtil().pixelRatio!;
}

/// Common responsive size values
class AppSizes {
  // Spacing values
  static double get xs => 4.w; // Extra small spacing
  static double get sm => 8.w; // Small spacing
  static double get md => 16.w; // Medium spacing
  static double get lg => 24.w; // Large spacing
  static double get xl => 32.w; // Extra large spacing
  static double get xxl => 48.w; // Extra extra large spacing

  // Font sizes
  static double get captionText => 12.sp; // Caption text
  static double get bodySmall => 14.sp; // Small body text
  static double get bodyText => 16.sp; // Regular body text
  static double get subtitle => 18.sp; // Subtitle text
  static double get title => 20.sp; // Title text
  static double get heading => 24.sp; // Heading text
  static double get largeHeading => 28.sp; // Large heading

  // Icon sizes
  static double get smallIcon => 16.w; // Small icons
  static double get icon => 24.w; // Regular icons
  static double get largeIcon => 32.w; // Large icons
  static double get extraLargeIcon => 48.w; // Extra large icons

  // Button sizes
  static double get buttonHeight => 48.h; // Standard button height
  static double get smallButtonHeight => 36.h; // Small button height
  static double get largeButtonHeight => 56.h; // Large button height

  // Border radius
  static double get smallRadius => 4.r; // Small border radius
  static double get radius => 8.r; // Standard border radius
  static double get largeRadius => 12.r; // Large border radius
  static double get circularRadius => 50.r; // Circular border radius

  // Card and container sizes
  static double get cardPadding => 16.w; // Card padding
  static double get containerPadding => 20.w; // Container padding
  static double get screenPadding => 16.w; // Screen edge padding

  // Grid spacing
  static double get gridSpacing => 12.w; // Grid item spacing
  static double get listSpacing => 8.w; // List item spacing
}
