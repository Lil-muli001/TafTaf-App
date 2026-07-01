import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:taftaf/app.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the native splash until the Flutter splash screen dismisses it.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Fire visibility callbacks every frame so card slideshows start/stop immediately.
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  // Use bundled Poppins fonts — no network requests needed
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: TafTafApp()));
}
