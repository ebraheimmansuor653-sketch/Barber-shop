import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/barber_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../manager/booking_flow/booking_flow_cubit.dart';
import '../manager/booking_flow/booking_flow_state.dart';
import '../theme/shop_colors.dart';
import 'select_appointment_page.dart';

class ShopDetailsPage extends StatelessWidget {
  final String shopId;

  const ShopDetailsPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingFlowCubit>()..loadShop(shopId),
      child: const _ShopDetailsView(),
    );
  }
}

class _ShopDetailsView extends StatelessWidget {
  const _ShopDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopColors.surface,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          if (state.step == BookingFlowStep.loading || state.shop == null) {
            return const Center(
              child: CircularProgressIndicator(color: ShopColors.primary),
            );
          }
          if (state.step == BookingFlowStep.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'حصل خطأ، حاول تاني',
                style: ShopTextStyles.bodyMd(color: ShopColors.error),
              ),
            );
          }

          final shop = state.shop!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: ShopColors.surfaceContainerLow,
                    expandedHeight: 220,
                    pinned: true,
                    iconTheme: const IconThemeData(color: ShopColors.textPrimary),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _ShopPhotosHeader(photoUrls: shop.photoUrls),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      ShopSpacing.md,
                      ShopSpacing.md,
                      ShopSpacing.md,
                      96, // room for the fixed book button
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(shop.name, style: ShopTextStyles.headlineLg()),
                        const SizedBox(height: ShopSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: ShopColors.textMuted),
                            const SizedBox(width: 4),
                            Text(shop.area, style: ShopTextStyles.bodySm()),
                          ],
                        ),
                        const SizedBox(height: ShopSpacing.lg),
                        Text('الحلاقين', style: ShopTextStyles.headlineSm()),
                        const SizedBox(height: ShopSpacing.sm),
                        _BarbersRow(
                          barbers: state.barbers,
                          selectedBarberId: state.selectedBarberId,
                          onSelect: (id) =>
                              context.read<BookingFlowCubit>().selectBarber(id),
                        ),
                        const SizedBox(height: ShopSpacing.lg),
                        Text('الخدمات', style: ShopTextStyles.headlineSm()),
                        const SizedBox(height: ShopSpacing.sm),
                        ...state.services.map((service) => _ServiceTile(
                              service: service,
                              selected: state.selectedServiceId == service.id,
                              onTap: () => context
                                  .read<BookingFlowCubit>()
                                  .selectService(service.id),
                            )),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BookButton(canBook: state.selectedServiceId != null),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopPhotosHeader extends StatelessWidget {
  final List<String> photoUrls;

  const _ShopPhotosHeader({required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return Container(color: ShopColors.surfaceContainer);
    }
    return PageView(
      children: photoUrls
          .map((url) => Image.network(url, fit: BoxFit.cover))
          .toList(),
    );
  }
}

class _BarbersRow extends StatelessWidget {
  final List<BarberEntity> barbers;
  final String? selectedBarberId;
  final ValueChanged<String?> onSelect;

  const _BarbersRow({
    required this.barbers,
    required this.selectedBarberId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BarberAvatar(
            name: 'أي حلاق متاح',
            photoUrl: null,
            selected: selectedBarberId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: ShopSpacing.sm),
          for (final barber in barbers) ...[
            _BarberAvatar(
              name: barber.name,
              photoUrl: barber.photoUrl,
              selected: selectedBarberId == barber.id,
              onTap: () => onSelect(barber.id),
            ),
            const SizedBox(width: ShopSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BarberAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _BarberAvatar({
    required this.name,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShopRadii.lg),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ShopColors.surfaceContainerHigh,
              child: CircleAvatar(
                radius: selected ? 27 : 29,
                backgroundColor: ShopColors.surfaceContainer,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, color: ShopColors.textMuted)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: ShopTextStyles.bodySm(
                  color: selected ? ShopColors.primary : ShopColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceEntity service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShopRadii.base),
      child: Container(
        margin: const EdgeInsets.only(bottom: ShopSpacing.sm),
        padding: const EdgeInsets.all(ShopSpacing.md),
        decoration: BoxDecoration(
          color: ShopColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ShopRadii.base),
          border: Border.all(
            color: selected ? ShopColors.primary : ShopColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: ShopTextStyles.bodyLg()),
                  const SizedBox(height: 2),
                  Text('${service.durationMinutes} دقيقة',
                      style: ShopTextStyles.bodySm()),
                ],
              ),
            ),
            Text('${service.price.toStringAsFixed(0)} ج.م',
                style: ShopTextStyles.labelLg(color: ShopColors.primary)),
            const SizedBox(width: ShopSpacing.sm),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? ShopColors.primary : ShopColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool canBook;

  const _BookButton({required this.canBook});

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
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: canBook
              ? () {
                  final cubit = context.read<BookingFlowCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const SelectAppointmentPage(),
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ShopColors.primary,
            disabledBackgroundColor: ShopColors.surfaceContainerHigh,
            foregroundColor: ShopColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShopRadii.base),
            ),
          ),
          child: const Text('احجز'),
        ),
      ),
    );
  }
}
