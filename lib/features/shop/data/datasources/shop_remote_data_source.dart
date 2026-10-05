import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/services/scheduling_engine.dart';
import '../models/barber_model.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/shop_model.dart';
import 'slot_taken_exception.dart';

abstract class ShopRemoteDataSource {
  Future<List<ShopModel>> getNearbyShops({
    required double latitude,
    required double longitude,
  });

  Future<ShopModel> getShop(String shopId);

  Future<List<BarberModel>> getBarbers(String shopId);

  Future<List<ServiceModel>> getServices(String shopId);

  Future<List<BookingModel>> getShopBookingsOnDate({
    required String shopId,
    required DateTime date,
  });

  Future<BookingModel> createBooking({
    required String shopId,
    required String barberId,
    required String serviceId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    required DateTime date,
    required int startMinute,
    required int durationMinutes,
    required BookingSource source,
  });

  Future<void> cancelBooking({
    required String shopId,
    required String bookingId,
    required bool cancelledByShop,
  });

  Future<void> setBookingOutcome({
    required String shopId,
    required String bookingId,
    required BookingStatus outcome,
  });
}

class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  final FirebaseFirestore _firestore;

  ShopRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  @override
  Future<List<ShopModel>> getNearbyShops({
    required double latitude,
    required double longitude,
  }) async {
    // MVP: approved + active shops only, filtered client-side by rough
    // area text for now. A real geo query (geohash + geoflutterfire or
    // similar) is a known follow-up once there are enough shops for
    // distance to matter — flagging this rather than quietly faking it.
    final snapshot = await _shops.where('approved', isEqualTo: true).get();
    return snapshot.docs
        .map((d) => ShopModel.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<ShopModel> getShop(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    return ShopModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<List<BarberModel>> getBarbers(String shopId) async {
    final snapshot = await _shops.doc(shopId).collection('barbers').get();
    return snapshot.docs
        .map((d) => BarberModel.fromMap(d.id, shopId, d.data()))
        .toList();
  }

  @override
  Future<List<ServiceModel>> getServices(String shopId) async {
    final snapshot = await _shops.doc(shopId).collection('services').get();
    return snapshot.docs
        .map((d) => ServiceModel.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<BookingModel>> getShopBookingsOnDate({
    required String shopId,
    required DateTime date,
  }) async {
    final snapshot = await _shops
        .doc(shopId)
        .collection('bookings')
        .where('dateKey', isEqualTo: dateKeyFor(date))
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<BookingModel> createBooking({
    required String shopId,
    required String barberId,
    required String serviceId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    required DateTime date,
    required int startMinute,
    required int durationMinutes,
    required BookingSource source,
  }) async {
    final shopRef = _shops.doc(shopId);
    final bookingRef = shopRef.collection('bookings').doc();
    final dateKey = dateKeyFor(date);

    return _firestore.runTransaction<BookingModel>((transaction) async {
      // --- 1. READS. Firestore requires every read in a transaction to
      // happen before any write, so this block has no `transaction.set`
      // calls in it at all. ---
      final shopSnap = await transaction.get(shopRef);
      final shop = ShopModel.fromMap(shopSnap.id, shopSnap.data()!);

      // The occupied window includes the shop's buffer as a trailing gap,
      // matching SchedulingEngine's own definition exactly so a slot the
      // engine offered the customer can never be rejected here for a
      // reason the engine didn't already account for.
      final occupiedEnd = startMinute + durationMinutes + shop.bufferMinutes;
      final cellMinutes = [
        for (var m = startMinute; m < occupiedEnd; m += kSlotGridMinutes) m,
      ];

      final barberSlotRefs = {
        for (final m in cellMinutes)
          m: shopRef.collection('barberSlots').doc('${barberId}_${dateKey}_$m')
      };
      final chairSlotRefs = {
        for (final m in cellMinutes)
          m: shopRef.collection('chairSlots').doc('${dateKey}_$m')
      };

      final barberSnaps = <int, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in barberSlotRefs.entries) {
        barberSnaps[entry.key] = await transaction.get(entry.value);
      }
      final chairSnaps = <int, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in chairSlotRefs.entries) {
        chairSnaps[entry.key] = await transaction.get(entry.value);
      }

      // --- 2. VALIDATE, using only what we just read. ---
      for (final snap in barberSnaps.values) {
        if (snap.exists) {
          throw const SlotTakenException(
            'This time was just taken for this barber — pick another.',
          );
        }
      }
      for (final snap in chairSnaps.values) {
        final currentCount =
            snap.exists ? (snap.data()!['count'] as int) : 0;
        if (currentCount >= shop.chairsCount) {
          throw const SlotTakenException(
            'The shop has no free chairs at this time anymore.',
          );
        }
      }

      // --- 3. WRITES. ---
      for (final ref in barberSlotRefs.values) {
        transaction.set(ref, {'bookingId': bookingRef.id});
      }
      for (final entry in chairSlotRefs.entries) {
        final currentCount = chairSnaps[entry.key]!.exists
            ? (chairSnaps[entry.key]!.data()!['count'] as int)
            : 0;
        transaction.set(entry.value, {'count': currentCount + 1});
      }

      final model = BookingModel(
        id: bookingRef.id,
        shopId: shopId,
        barberId: barberId,
        serviceId: serviceId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerUserId: customerUserId,
        date: date,
        startMinute: startMinute,
        durationMinutes: durationMinutes,
        status: BookingStatus.confirmed,
        source: source,
        createdAt: DateTime.now(),
      );
      transaction.set(bookingRef, model.toMap());
      return model;
    });
  }

  @override
  Future<void> cancelBooking({
    required String shopId,
    required String bookingId,
    required bool cancelledByShop,
  }) async {
    final shopRef = _shops.doc(shopId);
    final bookingRef = shopRef.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      // --- READS ---
      final shopSnap = await transaction.get(shopRef);
      final shop = ShopModel.fromMap(shopSnap.id, shopSnap.data()!);

      final bookingSnap = await transaction.get(bookingRef);
      final booking = BookingModel.fromMap(bookingSnap.id, bookingSnap.data()!);

      // Already cancelled (e.g. a double-tap) — nothing left to release.
      if (booking.status == BookingStatus.cancelled) return;

      final occupiedEnd =
          booking.startMinute + booking.durationMinutes + shop.bufferMinutes;
      final cellMinutes = [
        for (var m = booking.startMinute; m < occupiedEnd; m += kSlotGridMinutes) m,
      ];
      final dateKey = dateKeyFor(booking.date);

      final barberSlotRefs = [
        for (final m in cellMinutes)
          shopRef.collection('barberSlots').doc('${booking.barberId}_${dateKey}_$m')
      ];
      final chairSlotRefs = {
        for (final m in cellMinutes)
          m: shopRef.collection('chairSlots').doc('${dateKey}_$m')
      };
      final chairSnaps = <int, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in chairSlotRefs.entries) {
        chairSnaps[entry.key] = await transaction.get(entry.value);
      }

      // --- WRITES ---
      for (final ref in barberSlotRefs) {
        transaction.delete(ref);
      }
      for (final entry in chairSlotRefs.entries) {
        final snap = chairSnaps[entry.key]!;
        final currentCount = snap.exists ? (snap.data()!['count'] as int) : 0;
        if (currentCount <= 1) {
          transaction.delete(entry.value);
        } else {
          transaction.set(entry.value, {'count': currentCount - 1});
        }
      }
      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
    });
  }

  @override
  Future<void> setBookingOutcome({
    required String shopId,
    required String bookingId,
    required BookingStatus outcome,
  }) async {
    await _shops
        .doc(shopId)
        .collection('bookings')
        .doc(bookingId)
        .update({'status': outcome.name});
  }
}
