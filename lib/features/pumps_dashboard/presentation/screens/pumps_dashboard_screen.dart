import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/pumps_dashboard/domain/entities/pump.dart';
import 'package:gazstation/features/pumps_dashboard/presentation/widgets/pumps_list.dart';
import 'package:gazstation/features/station_list/data/models/remote_gas_station_models.dart';
import 'package:gazstation/features/station_list/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_centered_message.dart';

enum PumpDateFilter { day, week, month, year, all }

extension PumpDateFilterX on PumpDateFilter {
  String get label {
    switch (this) {
      case PumpDateFilter.day:
        return 'Jour';
      case PumpDateFilter.week:
        return 'Semaine';
      case PumpDateFilter.month:
        return 'Mois';
      case PumpDateFilter.year:
        return 'Année';
      case PumpDateFilter.all:
        return 'Tout';
    }
  }

  Duration get duration {
    switch (this) {
      case PumpDateFilter.day:
        return const Duration(days: 1);
      case PumpDateFilter.week:
        return const Duration(days: 7);
      case PumpDateFilter.month:
        return const Duration(days: 30);
      case PumpDateFilter.year:
        return const Duration(days: 365);
      case PumpDateFilter.all:
        return const Duration(days: 3650);
    }
  }
}

class PumpsDashboardScreen extends ConsumerStatefulWidget {
  const PumpsDashboardScreen({super.key, required this.stationId});

  final String stationId;

  @override
  ConsumerState<PumpsDashboardScreen> createState() =>
      _PumpsDashboardScreenState();
}

class _PumpsDashboardScreenState extends ConsumerState<PumpsDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  PumpDateFilter _selectedFilter = PumpDateFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pumpsAsync = ref.watch(pumpsProvider(widget.stationId));

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
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
            'Visualisation des Pompes',
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
      ),
      body: SafeArea(
        child: pumpsAsync.when(
          data: (data) => _buildContent(context, data.pumps, data.transactions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => StationCenteredMessage(
            title: 'Erreur',
            message: 'Impossible de charger les données des pompes.\n$error',
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Pump> pumps,
    List<PumpTransactionDto> transactions,
  ) {
    if (pumps.isEmpty) {
      return const StationCenteredMessage(
        title: 'Aucune pompe trouvée',
        message: 'Aucune pompe n\'est disponible pour cette station.',
      );
    }

    final filteredPumps = _applySearchFilter(pumps);
    final transactionsByDate = _filterTransactionsByDate(transactions);
    final filteredTransactions = _filterTransactionsByPumps(
      filteredPumps,
      transactionsByDate,
    );

    return Column(
      children: [
        _FiltersBar(
          controller: _searchController,
          selectedFilter: _selectedFilter,
          onQueryChanged: (value) => setState(() => _query = value),
          onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filteredPumps.isEmpty
              ? const StationCenteredMessage(
                  title: 'Aucun résultat',
                  message:
                      'Aucune pompe ne correspond à votre recherche ou filtre.',
                )
              : PumpsList(
                  pumps: filteredPumps,
                  transactions: filteredTransactions,
                ),
        ),
      ],
    );
  }

  List<Pump> _applySearchFilter(List<Pump> pumps) {
    final trimmedQuery = _query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return pumps;
    }

    return pumps.where((pump) {
      final pumpMatch = pump.label.toLowerCase().contains(trimmedQuery);
      final nozzleMatch = pump.nozzles.any(
        (nozzle) => nozzle.label.toLowerCase().contains(trimmedQuery),
      );
      return pumpMatch || nozzleMatch;
    }).toList();
  }

  List<PumpTransactionDto> _filterTransactionsByDate(
    List<PumpTransactionDto> transactions,
  ) {
    final threshold = DateTime.now().subtract(_selectedFilter.duration);
    return transactions.where((transaction) {
      final date = transaction.dateTime;
      if (date == null) {
        return true;
      }
      return !date.isBefore(threshold);
    }).toList();
  }

  List<PumpTransactionDto> _filterTransactionsByPumps(
    List<Pump> filteredPumps,
    List<PumpTransactionDto> transactions,
  ) {
    if (filteredPumps.isEmpty) {
      return const <PumpTransactionDto>[];
    }
    final allowedNozzleIds = filteredPumps
        .expand((pump) => pump.nozzles)
        .map((nozzle) => nozzle.id)
        .toSet();
    final allowedPumpIds = filteredPumps.map((pump) => pump.id).toSet();

    if (allowedNozzleIds.isEmpty && allowedPumpIds.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      final nozzleId = transaction.nozzleId;
      final pumpId = transaction.pumpId;
      if (nozzleId != null && allowedNozzleIds.contains(nozzleId)) {
        return true;
      }
      if (pumpId != null && allowedPumpIds.contains(pumpId)) {
        return true;
      }
      return false;
    }).toList();
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.controller,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final PumpDateFilter selectedFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PumpDateFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final options = PumpDateFilter.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Rechercher une pompe ou un pistolet',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: options.map((filter) {
              final selected = selectedFilter == filter;
              return ChoiceChip(
                label: Text(filter.label),
                selected: selected,
                onSelected: (_) => onFilterChanged(filter),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF4B5565),
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: AppTheme.navy,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFE0E4F0),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
