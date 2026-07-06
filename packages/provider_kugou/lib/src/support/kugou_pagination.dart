import 'dart:async';

final class KugouPagination {
  static Future<List<T>> fetchAll<T>({
    required Future<List<T>> Function(int page, int pageSize) fetchPage,
    int startPage = 1,
    int pageSize = 100,
    int maxPages = 50,
  }) async {
    final allItems = <T>[];
    var page = startPage;

    while (page < startPage + maxPages) {
      try {
        final pageItems = await fetchPage(page, pageSize);
        if (pageItems.isEmpty) {
          break;
        }
        allItems.addAll(pageItems);
        if (pageItems.length < pageSize) {
          break;
        }
        page++;
      } catch (e) {
        // Stop fetching on error and return what we have gathered so far.
        // The pullFavorites method can record partialFailureReason.
        rethrow;
      }
    }
    return allItems;
  }
}
