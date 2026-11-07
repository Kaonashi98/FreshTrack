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
        pageBuilder: (_, state) =>
            _instantPage(state, const ProductAddScreen()),
      ),
      GoRoute(
        path: '/products/new',
        pageBuilder: (_, state) => _instantPage(
          state,
          ProductFormScreen(
            templateId: state.uri.queryParameters['template'],
            scanOnOpen: state.uri.queryParameters['scan'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/products/scan-barcode',
        pageBuilder: (_, state) =>
            _instantPage(state, const BarcodeScannerScreen()),
      ),
      GoRoute(
        path: '/products/:id/edit',
        pageBuilder: (_, state) => _instantPage(
          state,
          ProductFormScreen(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        pageBuilder: (_, state) => _instantPage(
          state,
          ProductDetailsScreen(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/settings/privacy',
        pageBuilder: (_, state) =>
            _instantPage(state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: '/settings/appearance',
        pageBuilder: (_, state) =>
            _instantPage(state, const AppearanceSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (_, state) =>
            _instantPage(state, const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/data',
        pageBuilder: (_, state) =>
            _instantPage(state, const DataSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/about',
        pageBuilder: (_, state) =>
            _instantPage(state, const AboutSettingsScreen()),
      ),
      ShellRoute(
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, state) =>
                _instantPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (_, state) => _instantPage(
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
            pageBuilder: (_, state) =>
                _instantPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  ),
);
NoTransitionPage<void> _instantPage(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);
