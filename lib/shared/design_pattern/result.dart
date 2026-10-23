/// Resultado imutável de uma operação que pode falhar.
///
/// Use [Result.ok] para sucesso e [Result.error] para falha.
/// A UI deve desestruturar com `switch` ou `if case`.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error._(this.error);
  final Exception error;
}
