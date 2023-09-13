import 'dart:async';
// import 'dart:developer' show log;

class Debouncer<T> {
  final int milliseconds;
  Function? activeAction;
  T placeholder;

  Debouncer({
    required this.milliseconds,
    required this.placeholder,
  });

  Future<T> run(Future<T> Function() action) async {
    activeAction = action;
    T result = await Future.delayed(
      Duration(milliseconds: milliseconds),
      () => _goNoGo(action),
    );
    return result;
  }

  Future<T> _goNoGo(Function action) async {
    if (activeAction == action) {
      return action.call();
    } else {
      return placeholder;
    }
  }
}
