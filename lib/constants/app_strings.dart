class AppStrings {
  // App name
  static const String appName = 'Arunika World';

  // Landing / Welcome
  static const String welcomeHeading = 'Bring Animals to Life!';
  static const String welcomeSubtitle = 'Scan, learn, explore, and play!';
  static const String btnExplore = "Ayo Daftar";
  static const String btnTryDemo = 'Coba Demo';

  // Bottom Nav
  static const String navHome = 'Beranda';
  static const String navBelajar = 'Belajar';
  static const String navTumbuh = 'Tumbuh';
  static const String navParent = 'Profil';
  // Cards on the Belajar hub (formerly bottom-nav tabs).
  static const String navCollection = 'Kartu AR';
  static const String navDongeng = 'Dongeng';
  static const String belajarSubtitle = 'Pilih petualangan belajar hari ini!';

  // Belajar Huruf
  static const String hurufCardTitle = 'Huruf';
  static const String hurufCardDescription = 'Kenal huruf A sampai Z';
  static const String hurufTitle = 'Belajar Huruf';
  static const String hurufSubtitle = 'Kenal huruf A sampai Z';
  static const String hurufContinue = 'Lanjutkan belajar';
  static const String hurufAll = 'Semua Huruf';
  static String hurufDoneCount(int done, int total) =>
      '$done dari $total selesai';
  static const String hurufFree = 'Gratis';
  static const String hurufPremium = 'Premium';
  static const String hurufKenali = 'Kenali';
  static const String hurufTebalkan = 'Tebalkan';
  static String hurufLetterTitle(String upper) => 'Huruf $upper';
  static const String hurufListenSound = 'Dengar bunyi';
  static String hurufTraceTitle(String letter) => 'Tebalkan huruf $letter';
  static const String hurufTraceHint = 'Ikuti angka dan panah';
  static const String hurufRepeat = 'Ulangi';
  static const String hurufFinish = 'Selesai';
  static const String hurufNextTebalkan = 'Lanjut ke Tebalkan';
  static const String hurufLowerNow = 'Sekarang huruf kecilnya!';
  static String hurufSuccessBody(String upper) =>
      'Kamu berhasil menebalkan huruf $upper.';
  static const String hurufPlusStar = '+1 bintang';
  static String hurufNextLetter(String upper) => 'Lanjut ke huruf $upper';
  static const String hurufBackToList = 'Kembali ke daftar huruf';
  static const String hurufTraceAgain = 'Tebalkan lagi';
  static const String hurufUnlockAll = 'Buka semua huruf';
  static const String hurufTryAgain = 'Coba lagi';
  static const String hurufShowExample = 'Lihat contoh';
  static const String hurufHintLabel = 'Petunjuk:';
  static String hurufReasonOffPath(String upper) =>
      'Garisnya keluar dari jalur huruf $upper.';
  static const String hurufReasonTooShort = 'Garisnya belum sampai ujung.';
  static const String hurufReasonWrongDirection = 'Arah garisnya terbalik.';
  static const String hurufLoadError = 'Huruf belum bisa dimuat.';
  static const String hurufRetry = 'Coba lagi';
  static const String hurufAudioRetry = 'Putar ulang';
  static const String hurufNoChild =
      'Tambahkan data si kecil di Profil untuk mulai belajar huruf.';
  static const String hurufEmpty = 'Huruf segera hadir!';

  // Belajar Angka
  static const String angkaCardTitle = 'Angka';
  static const String angkaCardDescription =
      'Kenal angka, hitung benda, jawab soal';
  static const String angkaCardAction = 'Mulai';
  static const String angkaTitle = 'Belajar Angka';
  static const String angkaSubtitle = 'Kenal angka dan berhitung, yuk!';
  static const String angkaKenalTitle = 'Kenal Angka';
  static const String angkaKenalSubtitle = 'Ketuk angka untuk dengar bunyinya';
  static const String angkaHitungTitle = 'Hitung Benda';
  static const String angkaHitungSubtitle =
      'Hitung gambarnya, lalu ketik jawabannya';
  static String angkaLevelLabel(int n) => 'Level $n';
  static const String angkaStart = 'Mulai';
  static const String angkaContinue = 'Lanjut';
  static const String angkaPlayAgain = 'Main lagi';
  static String angkaAnswered(int answered, int total) =>
      '$answered/$total soal';
  static String angkaFinishFirst(int level) =>
      'Selesaikan Level $level untuk membuka';
  static const String angkaFree = 'Gratis';
  static const String angkaPremium = 'Premium';
  static String angkaQuestionHeader(int level, int q, int total) =>
      'Level $level · Soal $q dari $total';
  static const String angkaYourAnswer = 'Jawabanmu';
  static const String angkaCheck = 'Periksa';
  static const String angkaDelete = 'Hapus';
  static const String angkaListen = 'Dengar soal';
  static String angkaQuestionFallback(String benda) => 'Ada berapa $benda?';
  static String angkaSuccessBody(int n, String benda) =>
      'Ada $n $benda. Kamu pintar berhitung!';
  static String angkaRetryBody(int answer, String benda) =>
      'Jawabanmu $answer. Yuk, hitung ${benda}nya sekali lagi.';
  static const String angkaNextQuestion = 'Soal berikutnya';
  static const String angkaBackToMenu = 'Kembali ke menu';
  static const String angkaTryAgain = 'Coba lagi';
  static const String angkaListenAgain = 'Dengar soal lagi';
  static const String angkaLevelDoneTitle = 'Hore, level selesai!';
  static String angkaLevelDoneBody(int firstCorrect, int total) =>
      '$firstCorrect dari $total benar di percobaan pertama.';
  static const String angkaProvisional = 'Bintang disimpan saat online.';
  static const String angkaNextLevel = 'Level berikutnya';
  static const String angkaUnlockAll = 'Buka semua level';
  static const String angkaContinueLabel = 'ANGKA';
  static const String angkaLoadError = 'Angka belum bisa dimuat.';
  static const String angkaNoChild =
      'Tambahkan data si kecil di Profil untuk mulai belajar angka.';
  static const String angkaEmpty = 'Angka segera hadir!';
  static const String angkaReplay = 'Dengarkan';
  static const String angkaPrevious = 'Angka sebelumnya';
  static const String angkaNext = 'Angka berikutnya';
  static String angkaStarsLabel(int n) => '$n dari 3 bintang';

  // Home
  static const String homeGreeting = 'Halo, Selamat Datang! 👋';
  static const String homeGreetingName = 'Halo, ';
  static const String quickActionScan = 'Scan Mulai AR';
  static const String quickActionCollection = 'Koleksiku';
  static const String quickActionDongeng = 'Dongeng';
  static const String printableBanner = 'Unduh Kartu Printable';
  static const String printableBannerSub = 'Cetak & gunakan untuk AR!';

  // Collection
  static const String collectionTitle = 'Kartu AR';
  static const String filterAll = 'Semua';
  static const String filterTernak = 'Hewan Ternak';
  static const String filterHutan = 'Hutan';
  static const String filterLaut = 'Laut';

  // Animal Detail
  static const String funFactTitle = 'Fakta Seru 🐾';
  static const String btnScanAR = 'Scan di AR';
  static const String btnSound = 'Suara';
  static const String btnShare = 'Bagikan';

  // Dongeng
  static const String dongengTitle = 'Dongeng';
  static const String dongengFeatured = 'Cerita Pilihan';
  static const String dongengPopular = 'Cerita Populer';
  static const String dongengSeeAll = 'Lihat Semua';
  static const String btnReadNow = 'Baca Sekarang';
  static const String badgePremium = 'Premium';
  static const String dongengFeaturedBadge = 'Pilihan minggu ini';

  // Purchase actions on cards and list rows
  static const String btnBuy = 'Beli';
  static const String btnRead = 'Baca';
  static const String btnOpenAr = 'Buka AR';
  static const String badgeOwned = 'Dimiliki';
  static const String freeCaption = 'Gratis';

  // AR
  static const String arScanGuide = 'Arahkan kamera ke kartu AR';
  static const String arBtnInfo = 'Info';
  static const String arBtnSound = 'Suara';
  static const String arBtnDance = 'Tari';
  static const String arBtnEat = 'Makan';
  static const String funFactDialogTitle = 'Tahukah kamu?';

  // Reward
  static const String rewardHeading = '+10 ⭐';
  static const String rewardSubtitle = 'Kamu berhasil scan hewan baru!';
  static const String btnViewCollection = 'Lihat Koleksiku';

  // Premium
  static const String premiumTitle = 'Upgrade Premium';
  static const String premiumTabContent = 'Paket Konten';
  static const String premiumTabSubscription = 'Langganan';
  static const String badgeBestValue = 'BEST VALUE';

  // Payment
  static const String paymentTitle = 'Pembayaran';
  static const String paymentTotal = 'Total Pembayaran';
  static const String btnPayNow = 'Bayar Sekarang 🔒';

  // Unlock Success
  static const String unlockSuccessHeading = 'Yeay! 🎉';
  static const String unlockSuccessSubtitle = 'Konten premium berhasil dibuka!';
  static const String btnStartExplore = 'Mulai Jelajah';

  // General
  static const String locked = 'Terkunci';
  static const String unlocked = 'Terbuka';
}
