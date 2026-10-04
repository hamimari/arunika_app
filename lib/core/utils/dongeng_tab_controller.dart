/// Set by [UnlockSuccessScreen] before navigating back to `/shell`, so the
/// freshly-created DongengListBloc (see app_router.dart's dongengScreen
/// builder) can surface the just-purchased story as the featured/main
/// display item, without filtering the rest of the list out.
///
/// Holds a product id (matched against `DongengResponse.productId`), not a
/// title — titles aren't guaranteed unique and a substring/search match can
/// pick the wrong story.
///
/// Deliberately does NOT hold a reference to the bloc itself — `/shell` and
/// everything under it (including its `BlocProvider<DongengListBloc>`) is
/// torn down and rebuilt from scratch on every `context.go('/shell')`, so a
/// stashed Bloc reference goes stale the moment that happens and throws
/// "Bad state: Cannot add new events after calling close" the next time
/// something tries to use it. Passing a plain value instead sidesteps that
/// entirely — it's consumed once, by whichever bloc instance is live when
/// `/shell` is next built.
class DongengTabController {
  static String? pendingHighlightProductId;
}
