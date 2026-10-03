enum PaymentMethod { cash, visa }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.visa:
        return 'Visa';
    }
  }
}
