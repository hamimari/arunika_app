class ApiPaths {
  static const String signup = "/auth/signup";
  static const String checkAvailability = "/auth/check-availability";
  static const String refreshToken = "/auth/refresh-token";
  static const String signin = "/auth/login";
  static const String findUserById = "/user/";
  static const String updateUser = "/user";
  static const String deleteAccount = "/user/me";
  static const String recordConsent = "/user/consent";
  static const String fairyTales = "/fairy-tales";
  static const String fairyTaleById = "/fairy-tales/";
  static const String dongengCategories = "/dongeng-categories";
  static const String forgotPassword = "/forgot-password";
  static const String resendVerification = "/auth/resend-verification";
  static const String arModelById = "/ar/cards/";
  static const String arCards = "/ar/cards";
  static const String arCategories = "/ar/categories";
  static const String arPrintablePdf = "/ar/printable-pdf";
  static const String paymentCreate = "/payment/create";
  static const String paymentCreateProduct = "/payment/create-product";
  static const String paymentPlayCreate = "/payment/play/create";
  static const String paymentPlayCreateProduct = "/payment/play/create-product";
  static const String paymentPlayVerify = "/payment/play/verify";
  static const String paymentPlayReportExternal = "/payment/play/report-external";
  static const String banners = "/banners";
  static const String categories = "/categories";
  static const String dongengHistory = "/fairy-tales/history";
  static String dongengPlay(String id) => "/fairy-tales/$id/play";
  static const String premiumPacks = "/premium/packs";
  static const String orders = "/orders";
  static String orderById(String id) => "/orders/$id";
  static const String featureFlags = "/app/feature-flags";
  static const String notificationToken = "/notifications/token";
  static String childGrowth(String childId) => "/children/$childId/growth";
  static String growthMeasurements(String childId) =>
      "/children/$childId/growth/measurements";
  static String growthMeasurement(String childId, String id) =>
      "/children/$childId/growth/measurements/$id";
  static String growthMeasurementRestore(String childId, String id) =>
      "/children/$childId/growth/measurements/$id/restore";

  // Belajar Huruf
  static const String hurufManifest = "/learn/huruf/manifest";
  static String hurufLetter(String id) => "/learn/huruf/letters/$id";
  static String hurufProgress(String childId) =>
      "/children/$childId/huruf/progress";
  static String hurufLetterProgress(String childId, String letterId) =>
      "/children/$childId/huruf/progress/$letterId";
  static const String angkaManifest = "/learn/angka/manifest";
  static String angkaNumber(int value) => "/learn/angka/numbers/$value";
  static String angkaLevel(String id) => "/learn/angka/levels/$id";
  static String angkaProgress(String childId) =>
      "/children/$childId/angka/progress";
  static String angkaSessions(String childId) =>
      "/children/$childId/angka/sessions";
  static String angkaSession(String childId, String sessionId) =>
      "/children/$childId/angka/sessions/$sessionId";
  static String angkaSessionComplete(String childId, String sessionId) =>
      "/children/$childId/angka/sessions/$sessionId/complete";
}
