import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_model.dart';
import 'credit_card_view.dart';

/// Apple Wallet tarzı, üst üste binen ve kaydırılarak gezilen kart yığını.
///
/// Öndeki kart ortada tam boyda durur. Üstündeki kartların yalnızca üst
/// şeridi, altındakilerin yalnızca alt şeridi görünür; merkezden
/// uzaklaştıkça küçülür ve hafifçe eğilirler.
///
/// Yukarı/aşağı sürükledikçe kartlar parmağı takip ederek sürekli kayar
/// (sayfa kayıyormuş gibi); bırakınca en yakın karta yumuşakça oturur.
class CardStack extends StatefulWidget {
  const CardStack({
    super.key,
    required this.cards,
    required this.itemBuilder,
    required this.onFrontTap,
    this.onFrontChanged,
  });

  final List<CardModel> cards;

  /// [isFront]: kart şu an önde mi (dokunma, çevirme, gösterme yalnızca onda).
  final Widget Function(BuildContext context, int index, bool isFront)
  itemBuilder;

  /// Öndeki karta dokunulunca (kartı çevirmek için).
  final ValueChanged<int> onFrontTap;

  /// Öne gelen kart değişince.
  final ValueChanged<int>? onFrontChanged;

  /// Merkezin üstünde/altında görünen en fazla kart sayısı.
  static const maxVisiblePerSide = 6;

  /// Seçili kartın üstündeki her kartın görünen şerit yüksekliği.
  static const peekAbove = 38.0;

  /// Seçili kartın altındaki her kartın görünen şerit yüksekliği.
  static const peekBelow = 28.0;

  /// Her adımda küçülme oranı.
  static const scaleStep = 0.07;

  /// Merkez dışındaki kartların sırayla değişen eğimi (tur cinsinden, ~2.2°).
  static const tilt = 0.006;

  /// Bir kart ilerlemek için gereken sürükleme mesafesi (piksel).
  static const dragPerCard = 70.0;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack>
    with SingleTickerProviderStateMixin {
  /// Sürekli konum: 2.0 → 3. kart tam önde, 2.5 → 3. ile 4. arasında.
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: (widget.cards.length ~/ 2).toDouble(),
  )..addListener(_onPositionChanged);

  late int _front = widget.cards.length ~/ 2;

  int get _lastIndex => widget.cards.length - 1;

  @override
  void didUpdateWidget(CardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.cards.length;
    final oldCount = oldWidget.cards.length;
    if (count == oldCount) return;
    // Konum dinleyicisi üst widget'ta setState tetikleyebildiği için
    // değişiklik build bittikten sonra yapılır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (count > oldCount) {
        // Yeni eklenen kart öne gelsin
        _animateTo(_lastIndex);
      } else if (_position.value > _lastIndex) {
        _position.value = _lastIndex.toDouble();
      }
    });
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _onPositionChanged() {
    setState(() {});
    final front = _position.value.round().clamp(0, _lastIndex);
    if (front != _front) {
      _front = front;
      HapticFeedback.selectionClick();
      widget.onFrontChanged?.call(front);
    }
  }

  void _animateTo(int target) {
    final distance = (target - _position.value).abs();
    _position.animateTo(
      target.toDouble(),
      duration: Duration(
        milliseconds: (260 + 140 * distance).clamp(200, 700).round(),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Parmak yukarı → sonraki (alttaki) kart öne gelir.
    final delta = -details.primaryDelta! / CardStack.dragPerCard;
    var next = _position.value + delta;
    if (next < 0 || next > _lastIndex) {
      // Uçlarda lastik etkisi
      next = _position.value + delta * 0.3;
    }
    _position.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = -(details.primaryVelocity ?? 0) / CardStack.dragPerCard;
    final projected = _position.value + velocity * 0.18;
    _animateTo(projected.round().clamp(0, _lastIndex));
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // Fare tekerleği / dokunmatik yüzey
    if (event is PointerScrollEvent && event.scrollDelta.dy != 0) {
      final step = event.scrollDelta.dy > 0 ? 1 : -1;
      _animateTo((_front + step).clamp(0, _lastIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _position.stop(),
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = min(constraints.maxWidth - 40, 420.0);
            final height = width / CreditCardView.aspectRatio;
            final left = (constraints.maxWidth - width) / 2;

            const maxSide = CardStack.maxVisiblePerSide;
            final p = _position.value;
            final above = p.clamp(0.0, maxSide.toDouble());
            final below = (_lastIndex - p).clamp(0.0, maxSide.toDouble());
            final total =
                above * CardStack.peekAbove +
                height +
                below * CardStack.peekBelow;
            // Yığını dikeyde ortala; sığmıyorsa üstten başla.
            final frontTop =
                max(0.0, (constraints.maxHeight - total) / 2) +
                above * CardStack.peekAbove;

            final placements = <_Placement>[];
            for (var i = 0; i < cards.length; i++) {
              final offset = i - p;
              final distance = offset.abs();
              final depth = min(distance, maxSide.toDouble());
              final scale = 1 - CardStack.scaleStep * depth;
              final double centerY;
              if (offset < 0) {
                // Üst kenar, öndeki kartın üstünden `depth` şerit yukarıda.
                centerY =
                    frontTop - depth * CardStack.peekAbove + height * scale / 2;
              } else {
                // Alt kenar, öndeki kartın altından `depth` şerit aşağıda.
                centerY =
                    frontTop +
                    height +
                    depth * CardStack.peekBelow -
                    height * scale / 2;
              }
              placements.add(
                _Placement(
                  index: i,
                  distance: distance,
                  top: centerY - height / 2,
                  scale: scale,
                  turns:
                      (i.isEven ? 1 : -1) * CardStack.tilt * min(distance, 1),
                  opacity: (maxSide + 1 - distance).clamp(0.0, 1.0),
                ),
              );
            }
            // Uzaktakiler önce çizilir; öndeki kart en üstte kalır.
            placements.sort((a, b) => b.distance.compareTo(a.distance));

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final e in placements)
                  Positioned(
                    key: ValueKey(cards[e.index].id),
                    left: left,
                    top: e.top,
                    width: width,
                    height: height,
                    child: _buildCard(context, e),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _Placement e) {
    final card = widget.cards[e.index];
    final isFront = e.index == _front;
    return IgnorePointer(
      ignoring: e.opacity == 0,
      child: Opacity(
        opacity: e.opacity,
        child: Transform.rotate(
          angle: e.turns * 2 * pi,
          child: Transform.scale(
            scale: e.scale,
            child: KeyedSubtree(
              key: ValueKey('stack_card_${card.id}'),
              child: Semantics(
                button: isFront,
                label: isFront
                    ? '${card.name}, çevirmek için dokunun'
                    : card.name,
                child: GestureDetector(
                  onTap: isFront ? () => widget.onFrontTap(e.index) : null,
                  child: widget.itemBuilder(context, e.index, isFront),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placement {
  const _Placement({
    required this.index,
    required this.distance,
    required this.top,
    required this.scale,
    required this.turns,
    required this.opacity,
  });

  final int index;
  final double distance;
  final double top;
  final double scale;
  final double turns;
  final double opacity;
}
