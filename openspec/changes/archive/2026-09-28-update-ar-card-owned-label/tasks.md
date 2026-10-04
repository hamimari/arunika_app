## 1. Implementation
- [x] 1.1 Show "Dimiliki" (grey, check) only when a card is unlocked and has a product, as a chip under the title
- [x] 1.2 Show "Gratis" (green, gift) as a chip under the title of an unlocked card with no product
- [x] 1.3 Remove the picture badge for owned cards, the "Sudah jadi milikmu" caption and the unused strings/parameters
- [x] 1.4 Update and add widget tests (free card, free guest, mixed list, bought card, chip position under the title)

## 2. Validation
- [x] 2.1 `openspec validate update-ar-card-owned-label --strict`
- [x] 2.2 `flutter test`
