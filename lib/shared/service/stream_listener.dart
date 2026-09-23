import 'dart:async';

import 'package:material_ui/material_ui.dart';

class StreamListener<T> extends StatefulWidget {
  final Stream<T> _stream;
  final FutureOr<void> Function(BuildContext context, T data) _onData;
  final Widget _child;

  const StreamListener({
    super.key,
    required this._stream,
    required this._onData,
    required this._child,
  });

  @override
  State<StreamListener<T>> createState() => _StreamListenerState<T>();
}

class _StreamListenerState<T> extends State<StreamListener<T>> {
  StreamSubscription<T>? subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._stream != widget._stream) {
      subscription?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    subscription = widget._stream.listen((data) {
      if (mounted) {
        widget._onData(context, data);
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget._child;
}
