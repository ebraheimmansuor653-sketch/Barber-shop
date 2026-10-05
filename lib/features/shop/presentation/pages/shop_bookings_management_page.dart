import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/barber_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_shop_bookings_on_date_usecase.dart';
import '../../domain/usecases/set_booking_outcome_usecase.dart';
import '../manager/shop_bookings/shop_bookings_cubit.dart';
import '../manager/shop_bookings/shop_bookings_state.dart';
import '../theme/shop_colors.dart';

/// Pass [lockedBarberId] when a barber account opens this screen: the
/// chips row is hidden and the list is pinned to that barber's own
/// bookings only, per the agreed permission rule. Leave it null for the
/// owner view, which shows "All" plus every barber.
class ShopBookingsManagementPage extends StatelessWidget {
  final String shopId;
  final List<BarberEntity> barbers;
  final List<ServiceEntity> services;
  final String? lockedBarberId;

  const ShopBookingsManagementPage({
    super.key,
    required this.shopId,
    required this.barbers,
    required this.services,
    this.lockedBarberId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopBookingsCubit(
        shopId,
        sl<GetShopBookingsOnDateUseCase>(),
        sl<CreateBookingUseCase>(),
        sl<CancelBookingUseCase>(),
        sl<SetBookingOutcomeUseCase>(),
      )
        ..loadDate(DateTime.now())
        ..selectBarber(lockedBarberId),
      child: _ShopBookingsView(
        barbers: barbers,
        services: services,
        lockedBarberId: lockedBarberId,
      ),
    );
  }
}

class _ShopBookingsView extends StatelessWidget {
  final List<BarberEntity> barbers;
  final List<ServiceEntity> services;
  final String? lockedBarberId;

  const _ShopBookingsView({
    required this.barbers,
    required this.services,
    required this.lockedBarberId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopColors.surface,
      appBar: AppBar(
        backgroundColor: ShopColors.surfaceContainerLow,
        title: Text('إدارة الحجوزات', style: ShopTextStyles.headlineSm()),
        iconTheme: const IconThemeData(color: ShopColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ShopColors.primary,
        foregroundColor: ShopColors.onPrimary,
        onPressed: () => _openManualBookingSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ShopBookingsCubit, ShopBookingsState>(
        builder: (context, state) {
          return Column(
            children: [
              _DatePickerBar(
                date: state.date,
                onPick: (date) => context.read<ShopBookingsCubit>().loadDate(date),
              ),
              if (lockedBarberId == null)
                _BarberChips(
                  barbers: barbers,
                  selectedBarberId: state.selectedBarberId,
                  onSelect: (id) =>
                      context.read<ShopBookingsCubit>().selectBarber(id),
                ),
              const Divider(color: ShopColors.hairline, height: 1),
              Expanded(
                child: state.step == ShopBookingsStep.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: ShopColors.primary))
                    : state.visibleBookings.isEmpty
                        ? Center(
                            child: Text('مفيش حجوزات في اليوم ده',
                                style: ShopTextStyles.bodyMd()))
                        : ListView.builder(
                            padding: const EdgeInsets.all(ShopSpacing.md),
                            itemCount: state.visibleBookings.length,
                            itemBuilder: (_, i) => _BookingCard(
                              booking: state.visibleBookings[i],
                              barberName: _barberName(state.visibleBookings[i].barberId),
                              serviceName: _serviceName(state.visibleBookings[i].serviceId),
                              showBarberName: lockedBarberId == null,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _barberName(String barberId) {
    return barbers.where((b) => b.id == barberId).firstOrNull?.name ?? 'حلاق';
  }

  String _serviceName(String serviceId) {
    return services.where((s) => s.id == serviceId).firstOrNull?.name ?? 'خدمة';
  }

  void _openManualBookingSheet(BuildContext context) {
    final cubit = context.read<ShopBookingsCubit>();
    final effectiveBarbers = lockedBarberId == null
        ? barbers
        : barbers.where((b) => b.id == lockedBarberId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: ShopColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ShopRadii.lg)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ManualBookingSheet(
          barbers: effectiveBarbers,
          services: services,
          date: cubit.state.date,
        ),
      ),
    );
  }
}

class _DatePickerBar extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerBar({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ShopSpacing.md),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onPick(picked);
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: ShopColors.primary, size: 18),
            const SizedBox(width: ShopSpacing.sm),
            Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(date),
                style: ShopTextStyles.headlineSm()),
          ],
        ),
      ),
    );
  }
}

class _BarberChips extends StatelessWidget {
  final List<BarberEntity> barbers;
  final String? selectedBarberId;
  final ValueChanged<String?> onSelect;

  const _BarberChips({
    required this.barbers,
    required this.selectedBarberId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ShopSpacing.md),
        children: [
          _Chip(label: 'الكل', selected: selectedBarberId == null, onTap: () => onSelect(null)),
          for (final barber in barbers) ...[
            const SizedBox(width: ShopSpacing.xs),
            _Chip(
              label: barber.name,
              selected: selectedBarberId == barber.id,
              onTap: () => onSelect(barber.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShopRadii.base),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ShopSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ShopColors.primary : ShopColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ShopRadii.base),
          border: Border.all(color: selected ? ShopColors.primary : ShopColors.hairline),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: ShopTextStyles.labelMd(
              color: selected ? ShopColors.onPrimary : ShopColors.textSecondary),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final String barberName;
  final String serviceName;
  final bool showBarberName;

  const _BookingCard({
    required this.booking,
    required this.barberName,
    required this.serviceName,
    required this.showBarberName,
  });

  String _formatTime(int minute) {
    final hour24 = minute ~/ 60;
    final min = minute % 60;
    final period = hour24 >= 12 ? 'م' : 'ص';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '${hour12.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
  }

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return ShopColors.primary;
      case BookingStatus.completed:
        return ShopColors.textSecondary;
      case BookingStatus.cancelled:
        return ShopColors.error;
      case BookingStatus.noShow:
        return ShopColors.error;
    }
  }

  String _statusLabel() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.completed:
        return 'تم';
      case BookingStatus.cancelled:
        return 'ملغي';
      case BookingStatus.noShow:
        return 'ما حضرش';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShopBookingsCubit>();
    final isActionable = booking.status == BookingStatus.confirmed;

    return Container(
      margin: const EdgeInsets.only(bottom: ShopSpacing.sm),
      padding: const EdgeInsets.all(ShopSpacing.md),
      decoration: BoxDecoration(
        color: ShopColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ShopRadii.base),
        border: Border.all(color: ShopColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(booking.startMinute), style: ShopTextStyles.headlineSm()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ShopRadii.sm),
                ),
                child: Text(_statusLabel(),
                    style: ShopTextStyles.bodySm(color: _statusColor())),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(booking.customerName, style: ShopTextStyles.bodyLg()),
          Text(booking.customerPhone, style: ShopTextStyles.bodySm()),
          const SizedBox(height: 4),
          Text(
            showBarberName ? '$serviceName • $barberName' : serviceName,
            style: ShopTextStyles.bodySm(),
          ),
          if (isActionable) ...[
            const SizedBox(height: ShopSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.setOutcome(booking.id, BookingStatus.completed),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ShopColors.textPrimary,
                      side: const BorderSide(color: ShopColors.hairline),
                    ),
                    child: const Text('تم'),
                  ),
                ),
                const SizedBox(width: ShopSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.setOutcome(booking.id, BookingStatus.noShow),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ShopColors.error,
                      side: const BorderSide(color: ShopColors.hairline),
                    ),
                    child: const Text('ما حضرش'),
                  ),
                ),
                const SizedBox(width: ShopSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.cancelBooking(booking.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ShopColors.error,
                      side: const BorderSide(color: ShopColors.hairline),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualBookingSheet extends StatefulWidget {
  final List<BarberEntity> barbers;
  final List<ServiceEntity> services;
  final DateTime date;

  const _ManualBookingSheet({
    required this.barbers,
    required this.services,
    required this.date,
  });

  @override
  State<_ManualBookingSheet> createState() => _ManualBookingSheetState();
}

class _ManualBookingSheetState extends State<_ManualBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _barberId;
  String? _serviceId;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _barberId = widget.barbers.firstOrNull?.id;
    _serviceId = widget.services.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: ShopSpacing.md,
        right: ShopSpacing.md,
        top: ShopSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ShopSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('حجز يدوي', style: ShopTextStyles.headlineSm()),
            const SizedBox(height: ShopSpacing.md),
            TextFormField(
              controller: _nameController,
              style: ShopTextStyles.bodyLg(),
              decoration: const InputDecoration(labelText: 'اسم الزبون'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: ShopSpacing.sm),
            TextFormField(
              controller: _phoneController,
              style: ShopTextStyles.bodyLg(),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم التليفون'),
              validator: (v) => (v == null || v.trim().length < 10) ? 'رقم غير صحيح' : null,
            ),
            const SizedBox(height: ShopSpacing.sm),
            DropdownButtonFormField<String>(
              value: _barberId,
              dropdownColor: ShopColors.surfaceContainer,
              decoration: const InputDecoration(labelText: 'الحلاق'),
              items: widget.barbers
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (v) => setState(() => _barberId = v),
            ),
            const SizedBox(height: ShopSpacing.sm),
            DropdownButtonFormField<String>(
              value: _serviceId,
              dropdownColor: ShopColors.surfaceContainer,
              decoration: const InputDecoration(labelText: 'الخدمة'),
              items: widget.services
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _serviceId = v),
            ),
            const SizedBox(height: ShopSpacing.sm),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'الوقت'),
                child: Text(
                  _time == null ? 'اختار الوقت' : _time!.format(context),
                  style: ShopTextStyles.bodyLg(),
                ),
              ),
            ),
            const SizedBox(height: ShopSpacing.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShopColors.primary,
                  foregroundColor: ShopColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ShopRadii.base),
                  ),
                ),
                child: const Text('إضافة الحجز'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_barberId == null || _serviceId == null || _time == null) return;

    final service = widget.services.firstWhere((s) => s.id == _serviceId);
    final startMinute = _time!.hour * 60 + _time!.minute;

    Navigator.pop(context);
    context.read<ShopBookingsCubit>().addManualBooking(
          barberId: _barberId!,
          serviceId: _serviceId!,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          startMinute: startMinute,
          durationMinutes: service.durationMinutes,
        );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
