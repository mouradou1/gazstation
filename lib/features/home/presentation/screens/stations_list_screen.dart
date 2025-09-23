import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/core/network/repository_error.dart';
import 'package:gazstation/features/home/data/repositories/gas_station_repository_provider.dart';
import 'package:gazstation/features/home/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/home/presentation/widgets/station_card.dart';
import 'package:gazstation/features/home/presentation/widgets/stations_list_header.dart';

class StationsListScreen extends ConsumerStatefulWidget {
  const StationsListScreen({super.key});

  @override
  ConsumerState<StationsListScreen> createState() => _StationsListScreenState();
}

class _StationsListScreenState extends ConsumerState<StationsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RepositoryError?>(repositoryErrorProvider, (previous, next) {
      if (next == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              duration: const Duration(seconds: 4),
            ),
          );

        ref.read(repositoryErrorProvider.notifier).clear();
      });
    });

    final stationsAsync = ref.watch(gasStationsProvider);

    final contentSlivers = stationsAsync.when<List<Widget>>(
      data: (stations) {
        final filteredStations = stations
            .where(
              (station) =>
                  station.name.toLowerCase().contains(_query.toLowerCase()) ||
                  station.address.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

        if (filteredStations.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Aucune station trouvée.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ];
        }

        return [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final station = filteredStations[index];
              return StationCard(
                station: station,
                onTap: () => context.pushNamed(
                  AppRoute.stationDetail.name,
                  pathParameters: {'stationId': station.id},
                ),
              );
            }, childCount: filteredStations.length),
          ),
        ];
      },
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Impossible de charger les stations.\n$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StationsListHeader(
                searchController: _searchController,
                onQueryChanged: _onQueryChanged,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Text(
                  'stations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ...contentSlivers,
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }
}
