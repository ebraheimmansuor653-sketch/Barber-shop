import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../manager/booking_flow/booking_flow_cubit.dart';
import '../manager/booking_flow/booking_flow_state.dart';
import '../theme/shop_colors.dart';
import 'booking_confirmed_page.dart';
import 'customer_details_sheet.dart';

class SelectAppointmentPage extends StatefulWidget {
  const SelectAppointmentPage({super.key});

  @override
  State<SelectAppointmentPage> createState() => _SelectAppointmentPageState();
}

class _SelectAppointmentPageState extends State<SelectAppointmentPage> {
  @override
  void initState() {
    super.initState();
    // Default to today — matches the screenshots' "اليوم" chip being
    // pre-selected when the screen first opens.
    final cubit = context.read<BookingFlowCubit>();
    if (cubit.state.selectedDate == null) {
      cubit.selectDate(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) => curr.step == BookingFlowStep.booked,
      listener: (context, state) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmedPage(booking: state.confirmedBooking!),
          ),
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: ShopColors.surface,
          appBar: AppBar(
            backgroundColor: ShopColors.surfaceContainerLow,
            title: Text('اختيار الموعد', style: ShopTextStyles.headlineSm()),
            iconTheme: const IconThemeData(color: ShopColors.textPrimary),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ShopSpacing.md),
                  children: [
                    _DateStrip(
                      selectedDate: state.selectedDate,
                      onSelect: (date) =>
                          context.read<BookingFlowCubit>().selectDate(date),
                    ),
                    const SizedBox(height: ShopSpacing.lg),
                    Text('الأوقات المتاحة', style: ShopTextStyles.headlineSm()),
                    const SizedBox(height: ShopSpacing.sm),
                    if (state.slotsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: ShopSpacing.xl),
                        child: Center(
                          child: CircularProgressIndicator(color: ShopColors.primary),
                        ),
                      )
                    else if (state.availableStartMinutes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: ShopSpacing.xl),
                        child: Text(
                          'مفيش مواعيد متاحة في اليوم ده',
                          style: ShopTextStyles.bodyMd(),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      _TimeSlotGrid(
                        startMinutes: state.availableStartMinutes,
                        selectedStartMinute: state.selectedStartMinute,
                        onSelect: (m) =>
                            context.read<BookingFlowCubit>().selectStartMinute(m),
                      ),
                  ],
                ),
              ),
              _ConfirmBar(
                enabled: state.selectedStartMinute != null &&
                    state.step != BookingFlowStep.bookingInProgress,
                loading: state.step == BookingFlowStep.bookingInProgress,
                errorMessage: state.step == BookingFlowStep.error
                    ? state.errorMessage
                    : null,
                onConfirm: () => _openCustomerDetails(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCustomerDetails(BuildContext context) {
    final cubit = context.read<BookingFlowCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: ShopColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ShopRadii.lg)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CustomerDetailsSheet(),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _DateStrip({required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) => DateTime(today.year, today.month, today.day + i));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: ShopSpacing.sm),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected = selectedDate != null &&
              selectedDate!.year == day.year &&
              selectedDate!.month == day.month &&
              selectedDate!.day == day.day;
          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(ShopRadii.base),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? ShopColors.primary : ShopColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ShopRadii.base),
                border: Border.all(
                  color: isSelected ? ShopColors.primary : ShopColors.hairline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // Needs Arabic date-symbol data loaded once at startup
                    // (`initializeDateFormatting('ar')` from
                    // package:intl/date_symbol_data_local.dart) — likely
                    // already handled by EasyLocalization's init, but
                    // confirm that if this throws on a fresh run.
                    i == 0 ? 'اليوم' : DateFormat('EEE', 'ar').format(day),
                    style: ShopTextStyles.bodySm(
                      color: isSelected ? ShopColors.onPrimary : ShopColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: ShopTextStyles.labelLg(
                      color: isSelected ? ShopColors.onPrimary : ShopColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  final List<int> startMinutes;
  final int? selectedStartMinute;
  final ValueChanged<int> onSelect;

  const _TimeSlotGrid({
    required this.startMinutes,
    required this.selectedStartMinute,
    required this.onSelect,
  });

  String _format(int minute) {
    final hour24 = minute ~/ 60;
    final min = minute % 60;
    final period = hour24 >= 12 ? 'م' : 'ص';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '${hour12.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: ShopSpacing.sm,
        crossAxisSpacing: ShopSpacing.sm,
        childAspectRatio: 2.4,
      ),
      itemCount: startMinutes.length,
      itemBuilder: (_, i) {
        final minute = startMinutes[i];
        final selected = selectedStartMinute == minute;
        return InkWell(
          onTap: () => onSelect(minute),
          borderRadius: BorderRadius.circular(ShopRadii.base),
          child: Container(
            decoration: BoxDecoration(
              color: ShopColors.surfaceContainer,
              borderRadius: BorderRadius.circular(ShopRadii.base),
              border: Border.all(
                color: selected ? ShopColors.primary : ShopColors.hairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _format(minute),
              style: ShopTextStyles.labelMd(
                color: selected ? ShopColors.primary : ShopColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onConfirm;

  const _ConfirmBar({
    required this.enabled,
    required this.loading,
    required this.errorMessage,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ShopSpacing.md,
        ShopSpacing.sm,
        ShopSpacing.md,
        ShopSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: ShopColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: ShopColors.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ShopSpacing.sm),
              child: Text(
                errorMessage!,
                style: ShopTextStyles.bodySm(color: ShopColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: enabled ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopColors.primary,
                disabledBackgroundColor: ShopColors.surfaceContainerHigh,
                foregroundColor: ShopColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ShopRadii.base),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ShopColors.onPrimary,
                      ),
                    )
                  : const Text('تأكيد حجز الموعد'),
            ),
          ),
        ],
      ),
    );
  }
}
