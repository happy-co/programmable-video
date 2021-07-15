class TwilioPageMeta {
  final int page;
  final int pageSize;
  final String firstPageUrl;
  final String previousPageUrl;
  final String url;
  final String nextPageUrl;
  final String key;

  TwilioPageMeta({
    required this.page,
    required this.pageSize,
    required this.firstPageUrl,
    required this.previousPageUrl,
    required this.url,
    required this.nextPageUrl,
    required this.key,
  });

  factory TwilioPageMeta.fromMap(Map<String, dynamic> data) {
    return TwilioPageMeta(
      page: data['page'],
      pageSize: data['pageSize'],
      firstPageUrl: data['firstPageUrl'],
      previousPageUrl: data['previousPageUrl'],
      url: data['url'],
      nextPageUrl: data['nextPageUrl'],
      key: data['key'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'pageSize': pageSize,
      'firstPageUrl': firstPageUrl,
      'previousPageUrl': previousPageUrl,
      'url': url,
      'nextPageUrl': nextPageUrl,
      'key': key,
    };
  }
}
