import 'package:branch_q/core/error/bank_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/models.dart';
import '../state/branch_providers.dart';

class SlotBookingScreen extends ConsumerStatefulWidget {
  final String branchId;
  final String serviceId;
  final String serviceName;

  const SlotBookingScreen({
    super.key,
    required this.branchId,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends ConsumerState<SlotBookingScreen> {
  String? _selectedSlotId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    const today = 'Today';
    final slotsAsync = ref.watch(slotsProvider((branchId: widget.branchId, date: today)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: AsyncValueView<List<BookingSlot>>(
        value: slotsAsync,
        onRetry: () => ref.invalidate(slotsProvider((branchId: widget.branchId, date: today))),
        data: (slots) => Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120), // Bottom padding for the floating button
                children: [
                  // Context Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.briefcase, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selected Service', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(
                                widget.serviceName,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Available 15-Minute Slots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ).animate().fadeIn(delay: 100.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Slots Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isSelected = _selectedSlotId == slot.id;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: slot.isFull
                              ? null
                              : () => setState(() => _selectedSlotId = slot.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: slot.isFull
                                  ? const Color(0xFFF1F5F9)
                                  : (isSelected ? const Color(0xFF2563EB) : Colors.white),
                              border: Border.all(
                                color: slot.isFull
                                    ? Colors.transparent
                                    : (isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot.startTime,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: slot.isFull
                                        ? const Color(0xFF94A3B8)
                                        : (isSelected ? Colors.white : const Color(0xFF334155)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      slot.isFull ? LucideIcons.lock : LucideIcons.users,
                                      size: 10,
                                      color: slot.isFull
                                          ? const Color(0xFF94A3B8)
                                          : (isSelected ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      slot.isFull ? 'Full' : '${slot.remainingCapacity} left',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: slot.isFull
                                            ? const Color(0xFF94A3B8)
                                            : (isSelected ? Colors.white70 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().scale(delay: (50 * index).ms, duration: 250.ms, curve: Curves.easeOutBack);
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom Pinned Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      onPressed: (_selectedSlotId == null || _isSubmitting)
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                final idempotencyKey = 'idem_${DateTime.now().millisecondsSinceEpoch}';
                                final repo = ref.read(branchRepositoryProvider);
                                final token = await repo.bookAppointment(
                                  branchId: widget.branchId,
                                  slotId: _selectedSlotId!,
                                  serviceId: widget.serviceId,
                                  idempotencyKey: idempotencyKey,
                                );

                                ref.read(activeTokenStateProvider.notifier).state = token;
                                if (context.mounted) {
                                  context.go('/token/${token.id}');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  final message = e is BankError ? e.message : 'Booking failed';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message), backgroundColor: const Color(0xFFDC2626)),
                                  );
                                  ref.invalidate(slotsProvider((branchId: widget.branchId, date: today)));
                                }
                              } finally {
                                if (mounted) setState(() => _isSubmitting = false);
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutQuad),
          ],
        ),
      ),
    );
  }
}