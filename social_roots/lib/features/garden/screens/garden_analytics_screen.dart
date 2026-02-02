import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';

class GardenAnalyticsScreen extends ConsumerStatefulWidget {
  const GardenAnalyticsScreen({super.key});

  @override
  ConsumerState<GardenAnalyticsScreen> createState() => _GardenAnalyticsScreenState();
}

class _GardenAnalyticsScreenState extends ConsumerState<GardenAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(gardenHealthProvider);
    final repo = ref.watch(plantRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Garden Insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Overall Health Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Garden Health', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 16),
                    healthAsync.when(
                      data: (health) => Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 120,
                                width: 120,
                                child: CircularProgressIndicator(
                                  value: health / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  color: _getColorForHealth(health),
                                ),
                              ),
                              Text(
                                '${health.round()}%',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getMessageForHealth(health),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error loading data'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Plant Distribution
            FutureBuilder<Map<PlantHealthState, int>>(
              future: repo.getHealthDistribution(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plant Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildStatRow('Thriving', data[PlantHealthState.thriving] ?? 0, Colors.green),
                    _buildStatRow('Thirsty', data[PlantHealthState.thirsty] ?? 0, Colors.amber),
                    _buildStatRow('Wilting', data[PlantHealthState.wilting] ?? 0, Colors.orange),
                    _buildStatRow('Critical', data[PlantHealthState.critical] ?? 0, Colors.red),
                    _buildStatRow('Dormant', data[PlantHealthState.dormant] ?? 0, Colors.grey),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12, 
            height: 12, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getColorForHealth(double health) {
    if (health >= 80) return Colors.green;
    if (health >= 50) return Colors.amber;
    return Colors.red;
  }

  String _getMessageForHealth(double health) {
    if (health >= 80) return "Your garden is thriving! The sun is shining. ☀️";
    if (health >= 50) return "Some plants need water. Clouds are gathering. ⛅";
    return "Emergency! Your garden needs attention immediately. 🌧️";
  }
}
