class CurrencyFormatter {
  static String symbolFor(String currency) {
    switch (currency.trim().toUpperCase()) {
      case 'EGP':
        return 'EGP';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SAR':
        return 'SAR';
      case 'AED':
        return 'AED';
      default:
        return currency.trim().toUpperCase();
    }
  }

  static String format(double amount, String currency) =>
      '${symbolFor(currency)}${amount.toStringAsFixed(2)}';
}
