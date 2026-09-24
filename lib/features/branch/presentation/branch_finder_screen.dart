import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/models.dart';
import '../state/branch_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BranchFinderScreen extends ConsumerWidget {
  const BranchFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BranchQ Finder'),
        actions: [
          IconButton(
            tooltip: 'Refresh branch list',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(branchesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(branchesProvider.future),
        child: AsyncValueView<List<Branch>>(
          value: branches,
          onRetry: () => ref.invalidate(branchesProvider),
          data: (items) => ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final branch = items[i];
              final isHigh = branch.crowdLevel == 'High';

              return Container(
                margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.building, color: Colors.blue),
                    ),
                    title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branch.address, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          '${branch.distanceKm} km away',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        '${branch.crowdLevel} Crowd',
                        style: TextStyle(
                          color: isHigh ? Colors.red.shade900 : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isHigh ? Colors.red.shade50 : Colors.green.shade50,
                      side: BorderSide(
                        color: isHigh ? Colors.red.shade200 : Colors.green.shade200,
                      ),
                    ),
                    onTap: () => context.push('/branch/${branch.id}'),
                  ),
                ),
              ).animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutQuad);
            },
          ),
        ),
      ),
    );
  }
}