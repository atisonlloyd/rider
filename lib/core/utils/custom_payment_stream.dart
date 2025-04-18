import 'package:rxdart/rxdart.dart';

class RideRepository {
  final BehaviorSubject<bool> _paymentPaidController =
      BehaviorSubject.seeded(false);

  Stream<bool> get paymentPaidStream => _paymentPaidController.stream;

  void updatePaymentReceived(bool value) {
    _paymentPaidController.add(value);
  }

  void dispose() {
    _paymentPaidController.close();
  }
}
