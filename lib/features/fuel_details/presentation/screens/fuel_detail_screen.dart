import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_header_card.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_summary_table.dart';
import 'package:gazstation/features/station_details/presentation/widgets/tank_snapshot.dart';

class FuelDetailScreen extends ConsumerWidget {
  const FuelDetailScreen({
    super.key,
    required this.stationId,
    required this.tank,
  });

  final String stationId;
  final FuelTank tank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarTitle = tank.label;

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              FuelHeaderCard(
                label: tank.label,
                capacity: '${tank.capacityLiters.toStringAsFixed(0)} L',
                volume: '${tank.currentVolumeLiters.toStringAsFixed(0)} L',
                height: '${tank.currentHeightCm.toStringAsFixed(0)} mm',
                lastSync: _formatDate(tank.lastSync),
              ),
              const SizedBox(height: 20),
              FuelSummaryTable(summary: tank.summary),
              const SizedBox(height: 20),
              TankSnapshot(
                tank: tank,
                onSeeDetails: () {},
                showSeeDetails: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
