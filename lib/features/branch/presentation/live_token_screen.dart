import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/models.dart';
import '../state/branch_providers.dart';

class LiveTokenScreen extends ConsumerWidget {
  final String tokenId;
  const LiveTokenScreen({super.key, required this.tokenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveToken = ref.watch(tokenPollingProvider(tokenId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy / Slate background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Live Queue Token', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: AsyncValueView<LiveToken>(
        value: liveToken,
        data: (token) {
          final isServing = token.status == 'SERVING';
          final isNext = token.status == 'NEXT';

          // Dynamic colors based on queue status
          Color statusColor = isServing ? Colors.greenAccent : (isNext ? Colors.orangeAccent : Colors.blueAccent);
          Color statusBg = isServing 
              ? Colors.green.withValues(alpha: 0.15) 
              : (isNext ? Colors.orange.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15));
          String statusText = isServing ? 'NOW SERVING' : (isNext ? 'YOU ARE NEXT' : 'WAITING IN LINE');

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Status Pill with Pulse Animation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .fade(begin: 0.5, end: 1.0, duration: 1.seconds),
                  
                  const SizedBox(height: 56),
                  
                  // Giant Token Number
                  Text(
                    token.tokenNumber,
                    style: const TextStyle(
                      fontSize: 84,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    token.counter,
                    style: TextStyle(
                      fontSize: 22, 
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 64),
                  
                  // Metrics Glassmorphism Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricCard(label: 'Persons Ahead', value: '${token.position}'),
                        Container(width: 1, height: 48, color: Colors.white.withValues(alpha: 0.1)),
                        _MetricCard(label: 'Est. Wait', value: '${token.estimatedWaitMinutes}m'),
                      ],
                    ),
                  ).animate()
                   .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuart)
                   .fadeIn(duration: 500.ms),
                  
                  const Spacer(),
                  
                  // Bottom Action Button
                  FilledButton.icon(
                    icon: const Icon(LucideIcons.check),
                    label: const Text('I\'m Done Here', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.go('/'),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label, 
          style: TextStyle(
            color: Colors.grey.shade400, 
            fontSize: 13, 
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          )
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}