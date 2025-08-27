import 'comment.dart';
import 'update.dart';

abstract class DynamicList<T> {
  int get length;

  T operator [](int index);

  void operator []=(int index, T value);
}

class UpdateList implements DynamicList<Update> {
  final List<Update> _items;

  UpdateList() : _items = [];

  @override
  int get length => _items.length;

  @override
  Update operator [](int index) => _items[index];

  @override
  void operator []=(int index, Update value) {
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'index');
    }
    _items[index] = value;
  }

  void panic() {
    _items.clear();
  }

  void add(Update item) {
    _items.add(item);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'index');
    }
    _items.removeAt(index);
  }
}

class CommentList implements DynamicList<Comment> {
  final List<Comment> _items;

  CommentList() : _items = [];

  @override
  int get length => _items.length;

  @override
  Comment operator [](int index) => _items[index];

  @override
  void operator []=(int index, Comment value) {
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'index');
    }
    _items[index] = value;
  }

  void panic() {
    _items.clear();
  }

  void add(Comment item) {
    _items.add(item);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'index');
    }
    _items.removeAt(index);
  }
}