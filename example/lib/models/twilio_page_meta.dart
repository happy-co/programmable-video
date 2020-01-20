class TwilioPageMeta {
  final int page;
  final int pageSize;
  final String firstPageUrl;
  final String previousPageUrl;
  final String url;
  final String nextPageUrl;
  final String key;

  TwilioPageMeta({
    this.page,
    this.pageSize,
    this.firstPageUrl,
    this.previousPageUrl,
    this.url,
    this.nextPageUrl,
    this.key,
  });

  factory TwilioPageMeta.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
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
