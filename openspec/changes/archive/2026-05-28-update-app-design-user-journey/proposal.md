## Why

The current app screens do not match the intended Arunika World product vision — a magical, premium children's AR education app. The existing UI lacks the warm, playful aesthetic, clear user journeys (free and paid), and the full feature set (Home discovery, Collection, Dongeng list, AR scan flow, reward system, premium upsell) shown in the approved mockups. This alignment is needed before the app can be launched to market.

## What Changes

- **Home Screen**: Replace current landing/home UI with a new discovery-first home featuring a greeting header, quick-action buttons (Scan, Koleksiku, Dongeng), "Unduh Kartu Printable" banner, and bottom navigation bar (Beranda, Scan, Koleksi, Dongeng, Orang Tua).
- **Collection Screen**: Redesign the `vocab` screen into a full animal collection grid with category filter chips (Semua, Hewan Ternak, Hutan, Laut), unlock/lock states, star counter, and search/filter icons.
- **Animal Detail Page**: New card detail screen showing large animal image, fun facts, "Scan di AR" button, Sound and Share buttons, and favorite toggle.
- **Dongeng List Screen**: Update the existing dongeng list page to match the mockup — featured story card (Petualangan Rusa – Premium), "Cerita Populer" list with lock/unlock states, and premium badge. Keep the existing dongeng player screen unchanged.
- **AR Scan Flow**: Redesign the scan screen with camera viewfinder, animated scan guide, and AR experience screen with action buttons (Info, Suara, Tari, Makan), plus post-scan Fun Fact overlay and Reward screen (+10 stars, "Lihat Koleksiku").
- **Premium / Upgrade Screen**: New "Upgrade ke Premium" screen with Paket Konten / Langganan tabs, pack cards (Farm, Ocean, Dinosaur, All Access Pass) with IDR pricing.
- **Payment Screen**: New Pembayaran screen with local payment method selection (OVO, GoPay, DANA, ShopeePay, Transfer Bank, Kartu Kredit/Debit).
- **Unlock Success Screen**: Post-payment celebration screen listing newly unlocked content.
- **User Journey — Free Flow**: Welcome → Demo AR → Home → Explore free animals/dongeng → Discover premium content.
- **User Journey — Paid Flow**: Discover premium → Choose pack → Payment → Unlock success → Enjoy premium content → Progress/Journey screen.
- **Bottom Navigation**: Standardise to 5 tabs: Beranda, Scan, Koleksi, Dongeng, Orang Tua.
- **Design System**: Apply warm cream/orange/blue/gold palette, Poppins/Nunito typography, rounded corners, soft shadows, large touch targets throughout.

## Capabilities

### New Capabilities

- `home-screen`: Discovery home with greeting, quick actions, printable cards CTA, and daily animal highlight.
- `collection-screen`: Animal collection grid with category filters, lock/unlock states, and star counter.
- `animal-detail-screen`: Individual animal card detail with fun facts, AR scan CTA, sound, share, and favorite.
- `ar-scan-flow`: Full AR scan UX — camera scanner, AR experience with interaction buttons, fun fact overlay, and reward screen.
- `dongeng-list-screen`: Updated story list with featured premium story, popular stories list, and lock states.
- `premium-upgrade-screen`: Pack selection and subscription upgrade screen with IDR pricing.
- `payment-screen`: Local payment method screen (OVO, GoPay, DANA, ShopeePay, etc.).
- `unlock-success-screen`: Post-payment celebration screen confirming unlocked content.
- `user-journey-free`: End-to-end free user flow from welcome → demo AR → home → collection → dongeng.
- `user-journey-paid`: End-to-end paid user flow from premium discovery → pack selection → payment → unlock → premium content.
- `design-system`: Shared color palette, typography, spacing, and component styles applied app-wide.
- `bottom-navigation`: Standardised 5-tab bottom nav (Beranda, Scan, Koleksi, Dongeng, Orang Tua).

### Modified Capabilities

- `splash-screen`: Update welcome/landing screen to match new "Bring Animals to Life!" design with "Let's Explore!" and "Try Demo AR" buttons.

## Impact

- `lib/presentation/screens/home/` — full redesign
- `lib/presentation/screens/vocab/` — repurposed as collection screen
- `lib/presentation/screens/dongeng/` — list page redesign (player unchanged)
- `lib/presentation/screens/arscanner/` — AR scan flow redesign
- `lib/presentation/screens/landing/` — splash/welcome screen update
- `lib/presentation/navigation/` — bottom nav update to 5 tabs
- New screens added: animal detail, premium upgrade, payment, unlock success, reward
- `lib/constants/` and `lib/config/` — design tokens (colors, typography)
- No backend API changes required for UI-only screens; premium/payment screens will need backend integration in a later phase.
