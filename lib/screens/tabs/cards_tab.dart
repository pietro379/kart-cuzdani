import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../models/card_model.dart';
import '../../theme/card_swatches.dart';
import '../../theme/wallet_palette.dart';
import '../../utils/card_number_format.dart';
import '../../utils/text_format.dart';
import '../../widgets/card_back_view.dart';
import '../../widgets/card_stack.dart';
import '../../widgets/credit_card_view.dart';
import '../../widgets/flip_card.dart';
import '../edit_card_screen.dart';

class CardsTab extends StatefulWidget {
  const CardsTab({super.key});

  @override
  State<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<CardsTab> {
  /// Arka yüzü gösterilen kart (yalnızca öndeki kart çevrilebilir).
  String? _flippedId;

  /// Göz butonuna basılı tutuluyor mu (öndeki kartın bilgileri açılır).
  bool _revealing = false;

  /// Şu an öndeki kart (itemBuilder her yapımda günceller); düzenle/sil ona uygulanır.
  CardModel? _frontCard;

  Future<void> _editFront() async {
    final card = _frontCard;
    if (card == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => EditCardScreen(card: card)));
    // Düzenleme sonrası kart ters kalmasın.
    if (mounted) setState(() => _flippedId = null);
  }

  Future<void> _deleteFront() async {
    final card = _frontCard;
    if (card == null) return;
    final cards = AppScope.of(context).cards;
    final messenger = ScaffoldMessenger.of(context);
    final error = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: error, size: 36),
        title: Text('"${card.name}" silinsin mi?'),
        content: Text(
          '**** ${card.lastFour} ile biten kart bu cihazdan kalıcı olarak '
          'silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_card'),
            style: FilledButton.styleFrom(
              backgroundColor: error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await cards.remove(card.id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Kart silinemedi, tekrar deneyin.')),
      );
      return;
    }
    if (mounted) setState(() => _flippedId = null);
    messenger.showSnackBar(SnackBar(content: Text('"${card.name}" silindi')));
  }

  void _toggleFlip(CardModel card) {
    HapticFeedback.lightImpact();
    setState(() => _flippedId = _flippedId == card.id ? null : card.id);
  }

  /// Öne başka kart gelince çevrilmiş kart düzelir.
  void _onFrontChanged(int _) {
    if (_flippedId != null) setState(() => _flippedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.cards, scope.settings]),
      builder: (context, _) {
        final cards = scope.cards.cards;
        final settings = scope.settings;
        final holder = settings.userName.isEmpty
            ? 'KART SAHİBİ'
            : turkishUpperCase(settings.userName);

        return Column(
          children: [
            _Header(onLock: scope.onLock),
            Expanded(
              child: cards.isEmpty
                  ? _EmptyState(holderName: holder)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: CardStack(
                        key: const ValueKey('card_stack'),
                        cards: cards,
                        onFrontChanged: _onFrontChanged,
                        onFrontTap: (index) => _toggleFlip(cards[index]),
                        itemBuilder: (context, index, isFront) {
                          final card = cards[index];
                          if (isFront) _frontCard = card;
                          // Göz basılıyken yalnızca öndeki kartın bilgileri açılır.
                          final masked =
                              settings.maskCardNumbers &&
                              !(isFront && _revealing);
                          return _WalletCard(
                            card: card,
                            masked: masked,
                            holderName: holder,
                            flipped: _flippedId == card.id,
                          );
                        },
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  key: const ValueKey('edit_card_button'),
                  icon: Icons.edit_outlined,
                  tooltip: 'Kartı düzenle',
                  onPressed: cards.isEmpty ? null : _editFront,
                ),
                const SizedBox(width: 28),
                _RevealButton(
                  // Gizleme kapalıysa bilgiler zaten görünür; buton pasif.
                  enabled: cards.isNotEmpty && settings.maskCardNumbers,
                  revealing: _revealing,
                  onChanged: (value) => setState(() => _revealing = value),
                ),
                const SizedBox(width: 28),
                _ActionButton(
                  key: const ValueKey('delete_card_button'),
                  icon: Icons.delete_outline,
                  tooltip: 'Kartı sil',
                  onPressed: cards.isEmpty ? null : _deleteFront,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Ön yüzde numara, arka yüzde CVV ve kart şifresi bulunan çevrilebilir kart.
class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.card,
    required this.masked,
    required this.holderName,
    required this.flipped,
  });

  final CardModel card;
  final bool masked;
  final String holderName;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final background = CardSwatches.background(card.backgroundId);
    String secret(String value) => masked ? '*' * value.length : value;

    return FlipCard(
      flipped: flipped,
      front: CreditCardView(
        background: background,
        accent: CardSwatches.accent(card.accentId),
        brand: card.brand,
        name: card.name,
        numberText: formatCardNumber(card.number, masked: masked),
        expiryText: card.expiryText,
        holderName: holderName,
      ),
      back: CardBackView(
        background: background,
        brand: card.brand,
        cvvText: secret(card.cvv),
        pinText: card.pin == null ? null : secret(card.pin!),
      ),
    );
  }
}

/// Görseldeki "Manage / Your Cards" başlığı: koyu + gri iki satır.
class _Header extends StatelessWidget {
  const _Header({required this.onLock});

  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const style = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.8,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kartlarınızı',
                  style: style.copyWith(color: scheme.onSurface),
                ),
                Text(
                  'Yönetin',
                  style: style.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kilitle',
            icon: const Icon(Icons.lock_outline),
            onPressed: onLock,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.holderName});

  final String holderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Opacity(
          opacity: 0.35,
          child: CreditCardView(
            background: CardSwatches.background(
              CardSwatches.defaultBackgroundId,
            ),
            accent: CardSwatches.accent(CardSwatches.defaultAccentId),
            name: 'Kart İsmi',
            numberText: '**** **** **** ****',
            expiryText: 'AA/YY',
            holderName: holderName,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Henüz kayıtlı kart yok',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '"Kart Ekle" sekmesinden ilk kartınızı ekleyin. Kartlarınız '
          'yalnızca bu cihazda, şifreli olarak saklanır; internete hiçbir '
          'veri gönderilmez.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Göz butonunun iki yanındaki küçük yuvarlak işlem butonu (düzenle / sil).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          // Koyu temada simge zeminle kaynaşmasın; pasifken soluk kalır.
          foregroundColor: scheme.onSurface,
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          disabledBackgroundColor: scheme.surfaceContainerHigh.withValues(
            alpha: 0.4,
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}

/// Basılı tutulduğu sürece öndeki kartın gizli bilgilerini gösteren göz butonu.
/// Bırakılınca kart hemen eski (gizli) haline döner.
class _RevealButton extends StatelessWidget {
  const _RevealButton({
    required this.enabled,
    required this.revealing,
    required this.onChanged,
  });

  final bool enabled;
  final bool revealing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final active = enabled && revealing;

    void set(bool value) {
      if (!enabled || value == revealing) return;
      if (value) HapticFeedback.mediumImpact();
      onChanged(value);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Bilgileri göstermek için basılı tutun',
        excludeSemantics: true,
        child: Listener(
          key: const ValueKey('reveal_button'),
          onPointerDown: (_) => set(true),
          onPointerUp: (_) => set(false),
          onPointerCancel: (_) => set(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? palette.navSelected
                  : scheme.surfaceContainerHigh.withValues(alpha: 0.6),
              border: Border.all(
                color: active ? palette.navSelected : scheme.outline,
              ),
              boxShadow: active
                  ? [BoxShadow(color: palette.glow, blurRadius: 22)]
                  : null,
            ),
            child: Icon(
              active
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: active
                  ? scheme.surface
                  : enabled
                  ? palette.navSelected
                  : palette.navUnselected.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
