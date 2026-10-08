import 'dart:convert';

import '../models/card_model.dart';
import 'secure_store.dart';

/// Kartları JSON olarak şifreli depoya (flutter_secure_storage) yazar ve okur.
///
/// Tüm kartlar tek bir kayıtta, sürüm numarasıyla birlikte tutulur:
/// `{"version": 1, "cards": [ ... ]}`
class CardRepository {
  CardRepository(this._store);

  static const _key = 'cards.v1';
  static const _version = 1;

  final KeyValueStore _store;

  Future<List<CardModel>> loadAll() async {
    final raw = await _store.read(_key);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cards = decoded['cards'] as List<dynamic>;
    return [
      for (final card in cards)
        CardModel.fromJson(card as Map<String, dynamic>),
    ];
  }

  Future<void> saveAll(List<CardModel> cards) => _store.write(
    _key,
    jsonEncode({
      'version': _version,
      'cards': [for (final card in cards) card.toJson()],
    }),
  );
}
