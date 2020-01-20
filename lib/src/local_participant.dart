class LocalParticipant {
  final String _identity;

  final String _sid;

  String get sid {
    return _sid;
  }

  String get identity {
    return _identity;
  }

  LocalParticipant(this._identity, this._sid)
      : assert(_identity != null),
        assert(_sid != null);
}
