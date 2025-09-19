import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/core/navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: GazStationApp()));
}

class GazStationApp extends StatelessWidget {
  const GazStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const RouterProviderScope();
  }
}
