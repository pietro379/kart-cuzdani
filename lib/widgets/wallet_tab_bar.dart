import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/wallet_palette.dart';

class WalletTab {
  const WalletTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Arka planı olmayan, sade alt sekme çubuğu.
///
/// İkonlar ve yazılar doğrudan uygulama arka planının üzerinde durur.
/// Seçili sekmenin ikonu animasyonla büyür ve rengi değişir.
class WalletTabBar extends StatelessWidget {
  const WalletTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<WalletTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label: tabs[i].label,
                  excludeSemantics: true,
                  child: InkResponse(
                    key: ValueKey('tab_${tabs[i].label}'),
                    radius: 36,
                    onTap: () {
                      if (i == selectedIndex) return;
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                    child: _TabItem(
                      tab: tabs[i],
                      selected: i == selectedIndex,
                      color: i == selectedIndex
                          ? palette.navSelected
                          : palette.navUnselected,
                      labelStyle: textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.color,
    required this.labelStyle,
  });

  final WalletTab tab;
  final bool selected;
  final Color color;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: selected ? 1.3 : 1.0,
          duration: WalletTabBar._duration,
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: WalletTabBar._duration,
            builder: (context, value, _) => Icon(
              selected ? tab.selectedIcon : tab.icon,
              color: value,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: WalletTabBar._duration,
          style: (labelStyle ?? const TextStyle()).copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.4,
          ),
          child: Text(tab.label),
        ),
      ],
    );
  }
}
