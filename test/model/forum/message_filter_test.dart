import 'dart:async';

import 'package:dan_xi/model/forum/message_filter.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Message = ({int id, String? code});

OTMessageFeed<Message> makeFeed(
  Future<List<Message>?> Function(Message?) loadPage,
) {
  return OTMessageFeed<Message>(
    loadPage: loadPage,
    codeOf: (message) => message.code,
    idOf: (message) => message.id,
    cursorOf: (message) => message.id,
  );
}

List<int> ids(List<Message> messages) => messages.map((m) => m.id).toList();

void main() {
  test('filters the backend codes and keeps other messages in all', () {
    final codes = ['favorite', 'reply', 'mention', 'mail', null];
    List<String?> forFilter(OTMessageFilter filter) =>
        codes.where(filter.matches).toList();

    expect(forFilter(OTMessageFilter.all), codes);
    expect(forFilter(OTMessageFilter.subscription), ['favorite']);
    expect(forFilter(OTMessageFilter.reply), ['reply']);
    expect(forFilter(OTMessageFilter.mention), ['mention']);
  });

  test(
    'finds matches beyond empty filtered pages and reuses raw pages',
    () async {
      final pages = <List<Message>>[
        [(id: 1, code: 'favorite'), (id: 2, code: 'favorite')],
        [(id: 2, code: 'favorite'), (id: 3, code: 'mail')],
        [(id: 4, code: 'reply'), (id: 5, code: 'mention')],
      ];
      var calls = 0;
      final cursors = <int?>[];
      final feed = makeFeed((last) async {
        cursors.add(last?.id);
        return calls < pages.length ? pages[calls++] : [];
      });
      final replies = feed.view(OTMessageFilter.reply);

      expect(ids(await replies.nextPage()), [4]);
      expect(cursors, [null, 2, 3]);
      expect(await replies.nextPage(), isEmpty);
      expect(ids(await feed.view(OTMessageFilter.all).nextPage()), [
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(ids(await feed.view(OTMessageFilter.subscription).nextPage()), [
        1,
        2,
      ]);
      expect(ids(await feed.view(OTMessageFilter.mention).nextPage()), [5]);
      expect(calls, 3);
    },
  );

  test('stops if an unpaginated server ignores the time cursor', () async {
    var calls = 0;
    final feed = makeFeed((_) async {
      calls++;
      return [(id: 1, code: 'favorite')];
    });

    expect(await feed.view(OTMessageFilter.reply).nextPage(), isEmpty);
    expect(calls, 2);
  });

  test('a failed request can be retried', () async {
    var calls = 0;
    final feed = makeFeed((_) async {
      if (calls++ == 0) throw StateError('network error');
      return [(id: 1, code: 'reply')];
    });
    final view = feed.view(OTMessageFilter.reply);

    await expectLater(view.nextPage(), throwsStateError);
    expect(ids(await view.nextPage()), [1]);
  });

  test('filter views share an in-flight request', () async {
    final pending = Completer<List<Message>?>();
    var calls = 0;
    final feed = makeFeed((_) {
      calls++;
      return pending.future;
    });
    final all = feed.view(OTMessageFilter.all).nextPage();
    final subscriptions = feed.view(OTMessageFilter.subscription).nextPage();
    pending.complete([(id: 1, code: 'favorite')]);

    expect(ids(await all), [1]);
    expect(ids(await subscriptions), [1]);
    expect(calls, 1);
  });

  test('a cancelled view stops fetching after its pending page', () async {
    final pending = Completer<List<Message>?>();
    var calls = 0;
    final feed = makeFeed((_) {
      calls++;
      return pending.future;
    });
    final view = feed.view(OTMessageFilter.reply);
    final result = view.nextPage();
    view.cancel();
    pending.complete([(id: 1, code: 'favorite')]);

    expect(await result, isEmpty);
    expect(calls, 1);
  });
}
