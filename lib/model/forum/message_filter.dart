/// The message codes are defined by the forum backend.
enum OTMessageFilter {
  all(null),
  subscription('favorite'),
  reply('reply'),
  mention('mention');

  const OTMessageFilter(this.code);

  final String? code;

  /// Keep unknown message types accessible through the unfiltered view.
  bool matches(String? messageCode) => code == null || code == messageCode;
}

/// Loads raw pages once and lets each filter browse the same messages.
class OTMessageFeed<T> {
  OTMessageFeed({
    required this.loadPage,
    required this.codeOf,
    required this.idOf,
    required this.cursorOf,
  });

  final Future<List<T>?> Function(T? lastMessage) loadPage;
  final String? Function(T message) codeOf;
  final Object? Function(T message) idOf;
  final Object? Function(T message) cursorOf;

  final List<T> _messages = [];
  final Set<Object> _ids = {};
  T? _lastMessage;
  bool _ended = false;
  Future<void>? _pending;

  OTMessageFeedView<T> view(OTMessageFilter filter) =>
      OTMessageFeedView._(this, filter);

  Future<void> _loadNextPage() async {
    final pending = _pending;
    if (pending != null) return pending;

    final future = _readNextPage();
    _pending = future;
    try {
      await future;
    } finally {
      if (identical(_pending, future)) _pending = null;
    }
  }

  Future<void> _readNextPage() async {
    final page = await loadPage(_lastMessage);
    if (page == null || page.isEmpty) {
      _ended = true;
      return;
    }

    // Some servers return all messages and ignore the time cursor. Stop if a
    // subsequent request has not advanced, rather than repeating that page.
    final cursor = cursorOf(page.last);
    final lastMessage = _lastMessage;
    if (lastMessage != null &&
        cursor != null &&
        cursor == cursorOf(lastMessage)) {
      _ended = true;
      return;
    }

    final newMessages = page.where((message) {
      final id = idOf(message);
      return id == null || _ids.add(id);
    }).toList();
    if (newMessages.isEmpty) {
      _ended = true;
      return;
    }
    _messages.addAll(newMessages);
    _lastMessage = page.last;
  }
}

/// A separate cursor keeps filter switches and in-flight loads independent.
class OTMessageFeedView<T> {
  OTMessageFeedView._(this._feed, this.filter);

  final OTMessageFeed<T> _feed;
  final OTMessageFilter filter;
  int _offset = 0;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<List<T>> nextPage() async {
    while (!_cancelled) {
      final available = _feed._messages.skip(_offset).toList();
      _offset = _feed._messages.length;
      final matching = available
          .where((message) => filter.matches(_feed.codeOf(message)))
          .toList();
      if (matching.isNotEmpty) return matching;
      if (_feed._ended) return [];
      // A raw page can contain no matching messages even when later pages do.
      await _feed._loadNextPage();
    }
    return [];
  }
}
