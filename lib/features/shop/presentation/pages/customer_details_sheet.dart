import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/booking_flow/booking_flow_cubit.dart';
import '../theme/shop_colors.dart';

/// Collects the customer's name and phone right before writing the
/// booking. This sheet does NOT itself perform OTP verification — that's
/// the separate Authentication feature's job (not yet built). For now it
/// just reads whatever's already signed in (if anything) via
/// [customerUserId]/[prefilledPhone], and otherwise asks for the number
/// as plain text; replace that fallback once phone-OTP login exists, per
/// the agreed rule that booking requires a verified phone.
class CustomerDetailsSheet extends StatefulWidget {
  final String? customerUserId;
  final String? prefilledPhone;

  const CustomerDetailsSheet({
    super.key,
    this.customerUserId,
    this.prefilledPhone,
  });

  @override
  State<CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<CustomerDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();
  late final _phoneController =
      TextEditingController(text: widget.prefilledPhone ?? '');

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
            Text('بياناتك', style: ShopTextStyles.headlineSm()),
            const SizedBox(height: ShopSpacing.md),
            _Field(
              controller: _nameController,
              label: 'الاسم',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: ShopSpacing.sm),
            _Field(
              controller: _phoneController,
              label: 'رقم التليفون',
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'رقم غير صحيح' : null,
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
                child: const Text('تأكيد الحجز'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    context.read<BookingFlowCubit>().confirmBooking(
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          customerUserId: widget.customerUserId,
        );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: ShopTextStyles.bodyLg(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ShopTextStyles.bodyMd(),
        filled: true,
        fillColor: ShopColors.surfaceContainerLow,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ShopColors.hairline),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ShopColors.primary, width: 2),
        ),
      ),
    );
  }
}
