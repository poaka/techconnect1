/// Strongly-typed Failure representations matching backend error codes
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) return '$message (Code: $code)';
    return message;
  }
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'Erreur de connexion réseau. Veuillez vérifier votre connexion.',
    String? code,
    dynamic details,
  ]) : super(code: code, details: details);

  const NetworkFailure.named(
    super.message, {
    super.code,
    super.details,
  });
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Une erreur serveur est survenue.',
    String? code,
    dynamic details,
  ]) : super(code: code, details: details);

  const ServerFailure.named(
    super.message, {
    super.code,
    super.details,
  });
}
