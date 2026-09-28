import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum PaymentOptionsStatus {
  /// Checking the user's subscription.
  loading,

  /// Options are shown (packages may still be loading or have failed).
  ready,

  /// The user's active subscription already covers everything — no options,
  /// prices or "Bayar" are shown.
  subscribed,
}

class PaymentOptionsState {
  final PaymentOptionsStatus status;

  /// The single product the screen was opened for — listed first as
  /// "Beli … saja". Null when opened for a package, or when renewing.
  final PurchasableItem? singleItem;

  /// Selectable packages, in the backend's sort order.
  final List<PurchasableItem> packages;
  final bool packagesLoading;
  final bool packagesFailed;
  final PurchasableItem selected;

  /// Set while a payment is being started — selection is frozen.
  final bool locked;

  /// The subscriber's current subscription: shown in the subscribed state,
  /// and — when [renewing] — the base the renewed end date is added to.
  final SubscriptionInfo? subscription;

  /// An active subscriber inside the renewal window: only subscription
  /// packages are offered and the summary shows the stacked end date.
  final bool renewing;

  const PaymentOptionsState({
    required this.status,
    required this.selected,
    this.singleItem,
    this.packages = const [],
    this.packagesLoading = false,
    this.packagesFailed = false,
    this.locked = false,
    this.subscription,
    this.renewing = false,
  });

  List<PurchasableItem> get options => [?singleItem, ...packages];

  /// For a renewal: the new expiry if [selected] is bought now — added on
  /// top of the current expiry, mirroring the backend's stacking.
  DateTime? get renewedUntil {
    final expires = subscription?.expiresAt;
    final days = selected.durationDays;
    if (!renewing || expires == null || days == null) return null;
    return expires.add(Duration(days: days));
  }

  PaymentOptionsState copyWith({
    PaymentOptionsStatus? status,
    List<PurchasableItem>? packages,
    bool? packagesLoading,
    bool? packagesFailed,
    PurchasableItem? selected,
    bool? locked,
    SubscriptionInfo? subscription,
    bool? renewing,
  }) {
    return PaymentOptionsState(
      status: status ?? this.status,
      singleItem: singleItem,
      packages: packages ?? this.packages,
      packagesLoading: packagesLoading ?? this.packagesLoading,
      packagesFailed: packagesFailed ?? this.packagesFailed,
      selected: selected ?? this.selected,
      locked: locked ?? this.locked,
      subscription: subscription ?? this.subscription,
      renewing: renewing ?? this.renewing,
    );
  }
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Drives the payment screen's option list: the item the screen was opened
/// for plus every active premium package, which one is selected (and so
/// what "Bayar" pays for), and whether the user is an active subscriber who
/// shouldn't be offered anything.
class PaymentOptionsCubit extends Cubit<PaymentOptionsState> {
  final PurchasableItem entry;
  final PremiumPackRepository _packs;
  final ProfileLoader _profiles;

  PaymentOptionsCubit({
    required this.entry,
    required PremiumPackRepository packs,
    required ProfileLoader profiles,
  }) : _packs = packs,
       _profiles = profiles,
       super(
         PaymentOptionsState(
           status: PaymentOptionsStatus.loading,
           selected: entry,
           singleItem: entry.kind == PurchaseKind.product ? entry : null,
         ),
       );

  Future<void> load() async {
    SubscriptionInfo? sub;
    try {
      sub = await _profiles.activeSubscription();
    } catch (_) {
      // Unknown: show the options — the backend still refuses (409) a
      // purchase an active subscriber doesn't need.
    }
    if (isClosed) return;

    // Only a non-Play subscription inside its renewal window can be renewed
    // here; Play subscriptions renew through Google Play itself.
    final renewing = sub != null && sub.canRenew && !sub.isGooglePlay;
    if (sub != null && !renewing) {
      emit(
        state.copyWith(
          status: PaymentOptionsStatus.subscribed,
          subscription: sub,
        ),
      );
      return;
    }

    if (renewing) {
      emit(
        PaymentOptionsState(
          status: PaymentOptionsStatus.ready,
          selected: entry,
          packagesLoading: true,
          subscription: sub,
          renewing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: PaymentOptionsStatus.ready,
          packagesLoading: true,
        ),
      );
    }
    await loadPackages();
  }

  Future<void> loadPackages() async {
    emit(state.copyWith(packagesLoading: true, packagesFailed: false));
    try {
      final packs = await _packs.fetchPacks();
      if (isClosed) return;
      var items = packs.map(PurchasableItem.fromPackage).toList();
      if (state.renewing) {
        items = items.where((p) => p.isSubscriptionPurchase).toList();
      }
      emit(
        state.copyWith(
          packages: items,
          packagesLoading: false,
          selected: _initialSelection(items),
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(packagesLoading: false, packagesFailed: true));
    }
  }

  /// The entry item when it's in the list; when renewing, the subscriber's
  /// current plan (matched by name), else the entry if it's a subscription,
  /// else the first plan.
  PurchasableItem _initialSelection(List<PurchasableItem> items) {
    PurchasableItem? byId(String id) {
      for (final i in items) {
        if (i.id == id) return i;
      }
      return null;
    }

    if (state.renewing) {
      final plan = state.subscription?.planName;
      for (final i in items) {
        if (i.name == plan) return i;
      }
      final entryMatch = byId(entry.id);
      if (entryMatch != null) return entryMatch;
      return items.isNotEmpty ? items.first : entry;
    }
    if (entry.kind == PurchaseKind.product) return entry;
    return byId(entry.id) ?? entry;
  }

  void select(PurchasableItem item) {
    if (state.locked || state.status != PaymentOptionsStatus.ready) return;
    emit(state.copyWith(selected: item));
  }

  /// Freezes (or releases) the selection while a payment is being started.
  void setLocked(bool locked) => emit(state.copyWith(locked: locked));

  /// The backend refused to start the payment (409 SUBSCRIPTION_ACTIVE).
  void markSubscriptionActive() {
    emit(
      state.copyWith(status: PaymentOptionsStatus.subscribed, locked: false),
    );
  }
}
