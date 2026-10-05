import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/booking_entity.dart';
import '../theme/shop_colors.dart';

class BookingConfirmedPage extends StatelessWidget {
  final BookingEntity booking;

  const BookingConfirmedPage({super.key, required this.booking});

  String _formatTime(int minute) {
    final hour24 = minute ~/ 60;
    final min = minute % 60;
    final period = hour24 >= 12 ? 'م' : 'ص';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '${hour12.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ShopSpacing.md),
          children: [
            const SizedBox(height: ShopSpacing.lg),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ShopColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ShopRadii.lg),
                ),
                child: const Icon(Icons.check, color: ShopColors.primary, size: 32),
              ),
            ),
            const SizedBox(height: ShopSpacing.md),
            Text(
              'تم تأكيد حجزك بنجاح!',
              style: ShopTextStyles.headlineLg(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ShopSpacing.xs),
            Text(
              'هتلاقي تفاصيل الموعد في صفحة حجوزاتي',
              style: ShopTextStyles.bodyMd(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ShopSpacing.lg),
            Container(
              padding: const EdgeInsets.all(ShopSpacing.md),
              decoration: BoxDecoration(
                color: ShopColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ShopRadii.base),
                border: Border.all(color: ShopColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(
                    label: 'اليوم والتاريخ',
                    value: DateFormat('EEEE، d MMMM yyyy', 'ar').format(booking.date),
                  ),
                  const Divider(color: ShopColors.hairline, height: ShopSpacing.lg),
                  _Row(
                    label: 'الوقت المخصص',
                    value:
                        '${_formatTime(booking.startMinute)} • ${booking.durationMinutes} دقيقة',
                  ),
                  const Divider(color: ShopColors.hairline, height: ShopSpacing.lg),
                  _Row(label: 'رقم الحجز', value: booking.id.substring(0, 8)),
                ],
              ),
            ),
            const SizedBox(height: ShopSpacing.lg),
            Container(
              padding: const EdgeInsets.all(ShopSpacing.md),
              decoration: BoxDecoration(
                color: ShopColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ShopRadii.base),
                border: Border.all(color: ShopColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: ShopColors.textMuted),
                  const SizedBox(width: ShopSpacing.sm),
                  Expanded(
                    child: Text(
                      'المبلغ بيتسدد في الصالون — مفيش دفع جوه التطبيق.',
                      style: ShopTextStyles.bodySm(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ShopSpacing.xl),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShopColors.primary,
                  foregroundColor: ShopColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ShopRadii.base),
                  ),
                ),
                child: const Text('العودة للصفحة الرئيسية'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ShopTextStyles.bodySm()),
        Text(value, style: ShopTextStyles.labelLg()),
      ],
    );
  }
}
