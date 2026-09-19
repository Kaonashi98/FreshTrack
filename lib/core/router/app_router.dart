import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/presentation/dashboard/dashboard_screen.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/products/product_add_screen.dart';
import 'package:freshtrack/presentation/products/barcode_scanner_screen.dart';
import 'package:freshtrack/presentation/products/products_screen.dart';
import 'package:freshtrack/presentation/settings/about_settings_screen.dart';
import 'package:freshtrack/presentation/settings/appearance_settings_screen.dart';
import 'package:freshtrack/presentation/settings/data_settings_screen.dart';
import 'package:freshtrack/presentation/settings/notification_settings_screen.dart';
import 'package:freshtrack/presentation/settings/privacy_policy_screen.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';
import 'package:freshtrack/presentation/shell/main_shell.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/products/add',
        builder: (_, _) => const ProductAddScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (_, state) => ProductFormScreen(
          templateId: state.uri.queryParameters['template'],
          scanOnOpen: state.uri.queryParameters['scan'] == 'true',
        ),
      ),
      GoRoute(
        path: '/products/scan-barcode',
        builder: (_, _) => const BarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, state) =>
            ProductFormScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            ProductDetailsScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (_, _) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/data',
        builder: (_, _) => const DataSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (_, _) => const AboutSettingsScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, state) => _tabPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (_, state) => _tabPage(
              state,
              ProductsScreen(
                expirationDate: CivilDate.tryParse(
                  state.uri.queryParameters['expiresOn'] ?? '',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, state) => _tabPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  ),
);
CustomTransitionPage<void> _tabPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.018, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
    );
