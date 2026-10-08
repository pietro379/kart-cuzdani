import 'package:add_card_app/services/pin_hasher.dart';

/// Testleri hızlı tutmak için düşük iterasyonlu, isolate kullanmayan hasher.
const testHasher = PinHasher(iterations: 1000, runInBackground: false);
