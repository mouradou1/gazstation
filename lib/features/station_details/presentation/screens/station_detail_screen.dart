import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/station_list/domain/entities/gas_station.dart';
import 'package:gazstation/features/station_list/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_centered_message.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_detail_content.dart';

class StationDetailScreen extends ConsumerStatefulWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  ConsumerState<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen> {
  String? _selectedTankId;
  DateTime? _lastRefreshAt;
  GasStation? _latestStation;
  Timer? _refreshTimer;
  ProviderSubscription<AsyncValue<GasStation?>>? _stationSubscription;
  bool _isRefreshing = true;

  static const _refreshInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _listenToStationUpdates();
    _startAutoRefresh();
  }

  @override
  void didUpdateWidget(covariant StationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stationId != widget.stationId) {
      _selectedTankId = null;
      _lastRefreshAt = null;
      _latestStation = null;
      _stationSubscription?.close();
      _listenToStationUpdates();
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _stationSubscription?.close();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _listenToStationUpdates() {
    _stationSubscription = ref.listenManual<AsyncValue<GasStation?>>(
      stationDetailsProvider(widget.stationId),
      (_, next) {
        next.when(
          data: (station) {
            if (!mounted) {
              return;
            }
            setState(() {
              _latestStation = station;
              _lastRefreshAt = DateTime.now();
              _isRefreshing = false;
            });
          },
          loading: () {
            if (!mounted) {
              return;
            }
            setState(() => _isRefreshing = true);
          },
          error: (_, __) {
            if (!mounted) {
              return;
            }
            setState(() => _isRefreshing = false);
          },
        );
      },
    );
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isRefreshing = true);
      ref.invalidate(stationDetailsProvider(widget.stationId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationAsync = ref.watch(stationDetailsProvider(widget.stationId));
    final stationToDisplay = stationAsync.maybeWhen(
      data: (station) => station,
      orElse: () => _latestStation,
    );
    final appBarTitle = stationToDisplay?.name ?? 'Détails station';
    final lastError = stationAsync.maybeWhen(
      error: (error, _) => error,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        toolbarHeight: 84,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            appBarTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            onPressed: () {
              context.pushNamed(
                AppRoute.fuelSummary.name,
                pathParameters: {'stationId': widget.stationId},
              );
            },
            tooltip: 'Voir le résumé des cuves',
          ),
          IconButton(
            icon: const Icon(
              Icons.local_gas_station_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              context.pushNamed(
                AppRoute.pumpsDashboard.name,
                pathParameters: {'stationId': widget.stationId},
              );
            },
            tooltip: 'Voir les pompes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: stationToDisplay == null
            ? stationAsync.when(
                data: (_) => const StationCenteredMessage(
                  title: 'Station introuvable',
                  message: 'Cette station n’est plus disponible.',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => StationCenteredMessage(
                  title: 'Erreur',
                  message: 'Impossible de charger la station.\n$error',
                ),
              )
            : StationDetailContent(
                station: stationToDisplay,
                selectedTankId: _selectedTankId,
                lastRefreshAt: _lastRefreshAt,
                isRefreshing: _isRefreshing,
                errorMessage: lastError != null
                    ? 'Dernière tentative échouée.\n$lastError'
                    : null,
                onSelectTank: (value) =>
                    setState(() => _selectedTankId = value),
              ),
      ),
    );
  }
}
