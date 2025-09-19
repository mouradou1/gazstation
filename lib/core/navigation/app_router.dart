import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/auth/presentation/screens/login_screen.dart';
import 'package:gazstation/features/fuel_details/presentation/screens/fuel_detail_screen.dart';
import 'package:gazstation/features/home/presentation/screens/stations_list_screen.dart';
import 'package:gazstation/features/station_details/presentation/screens/station_detail_screen.dart';

enum AppRoute { login, stations, stationDetail, fuelDetail }

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/stations',
        name: AppRoute.stations.name,
        builder: (context, state) => const StationsListScreen(),
        routes: [
          GoRoute(
            path: ':stationId',
            name: AppRoute.stationDetail.name,
            builder: (context, state) {
              final stationId = state.pathParameters['stationId']!;
              return StationDetailScreen(stationId: stationId);
            },
            routes: [
              GoRoute(
                path: 'fuel/:fuelId',
                name: AppRoute.fuelDetail.name,
                builder: (context, state) {
                  final stationId = state.pathParameters['stationId']!;
                  final fuelId = state.pathParameters['fuelId']!;
                  return FuelDetailScreen(stationId: stationId, fuelId: fuelId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // Simple redirect: send users away from login once they reached stations.
      final loggedIn =
          state.fullPath != null && state.fullPath!.startsWith('/stations');
      if (loggedIn && state.fullPath == '/login') {
        return '/stations';
      }
      return null;
    },
  );
});

class RouterProviderScope extends ConsumerWidget {
  const RouterProviderScope({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
