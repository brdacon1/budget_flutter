import 'package:flutter/foundation.dart';
import 'result.dart';

/// Ação assíncrona sem argumentos exposta pelo ViewModel para a View.
///
/// Escutável ([Listenable]) para que a View reaja aos estados
/// `running`, `completed` e `error`.
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  bool get running => _running;

  bool _completed = false;
  bool get completed => _completed;

  bool _error = false;
  bool get error => _error;

  Result<T>? _result;
  Result<T>? get result => _result;

  Future<void> execute() async {
    _running = true;
    _completed = false;
    _error = false;
    notifyListeners();

    _result = await _action();

    _running = false;
    _completed = _result is Ok<T>;
    _error = _result is Error<T>;
    notifyListeners();
  }

  void clearResult() {
    _completed = false;
    _error = false;
    _result = null;
    notifyListeners();
  }
}

/// Ação assíncrona com 1 argumento exposta pelo ViewModel para a View.
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A argument) _action;

  bool _running = false;
  bool get running => _running;

  bool _completed = false;
  bool get completed => _completed;

  bool _error = false;
  bool get error => _error;

  Result<T>? _result;
  Result<T>? get result => _result;

  Future<void> execute(A argument) async {
    _running = true;
    _completed = false;
    _error = false;
    notifyListeners();

    _result = await _action(argument);

    _running = false;
    _completed = _result is Ok<T>;
    _error = _result is Error<T>;
    notifyListeners();
  }

  void clearResult() {
    _completed = false;
    _error = false;
    _result = null;
    notifyListeners();
  }
}
