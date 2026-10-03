/// taxRate is a fraction straight from restaurant_settings.tax_rate (0.1 ==
/// 10%). Shared by cart_screen and receipt_screen so the displayed
/// percentage always matches whatever the restaurant actually configured,
/// instead of each screen hardcoding its own "(10%)" label that goes
/// stale the moment the real rate changes -- the charged amount was
/// already computed correctly, only the label lied about it.
String formatTaxPercent(double taxRate) {
  final percent = taxRate * 100;
  return percent % 1 == 0 ? percent.toStringAsFixed(0) : percent.toStringAsFixed(1);
}
