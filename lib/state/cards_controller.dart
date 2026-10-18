import 'package:flutter/foundation.dart';

import '../models/card_model.dart';
import '../services/card_repository.dart';

/// Kayıtlı kartların uygulama genelindeki durumu.
///
/// Kartlar, kart verisi PIN girilmeden belleğe alınmasın diye uygulama
/// açılışında değil, kilit ilk açıldığında yüklenir.
class CardsController extends ChangeNotifier {
  CardsController(this._repository);

  final CardRepository _repository;

  List<CardModel> _cards = const [];

  List<CardModel> get cards => _cards;

  Future<void> load() async {
    _cards = List.unmodifiable(await _repository.loadAll());
    notifyListeners();
  }

  /// Önce depoya yazar; yazma başarısız olursa bellekteki liste değişmez.
  Future<void> add(CardModel card) async {
    final updated = List<CardModel>.unmodifiable([..._cards, card]);
    await _repository.saveAll(updated);
    _cards = updated;
    notifyListeners();
  }

  /// Aynı kimlikli kartı günceller; sıra korunur. Kimlik yoksa hiçbir şey yapmaz.
  Future<void> update(CardModel card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index < 0) return;
    final updated = List<CardModel>.unmodifiable([
      for (var i = 0; i < _cards.length; i++) i == index ? card : _cards[i],
    ]);
    await _repository.saveAll(updated);
    _cards = updated;
    notifyListeners();
  }

  /// Kartı depodan kalıcı olarak siler.
  Future<void> remove(String id) async {
    final updated = List<CardModel>.unmodifiable(
      _cards.where((c) => c.id != id),
    );
    if (updated.length == _cards.length) return;
    await _repository.saveAll(updated);
    _cards = updated;
    notifyListeners();
  }

  /// Tüm veriler silindikten sonra bellekteki kartları da temizler.
  void reset() {
    _cards = const [];
    notifyListeners();
  }
}
