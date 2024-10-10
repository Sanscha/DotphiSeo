import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetChecker {
  Future<bool> get hasConnection async {
    try {
      return await InternetConnectionChecker().hasConnection;
    } on Exception catch (_) {
      return false;
    }
  }
}
