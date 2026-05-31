class ApiPaths {
  static const String signup = "/auth/signup";
  static const String refreshToken = "/auth/refresh-token";
  static const String signin = "/auth/login";
  static const String findUserById = "/user/";
  static const String updateUser = "/user";
  static const String fairyTales = "/fairy-tales";
  static const String fairyTaleById = "/fairy-tales/";
  static const String forgotPassword = "/forgot-password";
  static const String arModelById = "/ar/cards/";
  static const String arCards = "/ar/cards";
  static const String arCategories = "/ar/categories";
  static const String arPrintablePdf = "/ar/printable-pdf";
  static const String animals = "/animals";
  static const String paymentCreate = "/payment/create";
  static const String banners = "/banners";
  static const String categories = "/categories";
  static const String dongengHistory = "/fairy-tales/history";
  static const String dongengPopular = "/fairy-tales/popular";
  static String dongengPlay(String id) => "/fairy-tales/$id/play";
  static const String premiumPacks = "/premium/packs";
  static const String countingQuestions = "/counting/questions";
  static const String countingProgress = "/counting/progress";
  static const String tracingItems = "/tracing/items";
  static const String tracingProgress = "/tracing/progress";
}
