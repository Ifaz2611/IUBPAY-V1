import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/vendor_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VendorApp()));
}

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(vendorRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    AppThemeState.setDark(isDark);
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.backgroundDark : AppColors.background,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);
    return MaterialApp.router(
      title: 'IUB PAY - Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
