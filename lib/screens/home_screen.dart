import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/app_background.dart';
import '../widgets/wallet_tab_bar.dart';
import 'tabs/add_card_tab.dart';
import 'tabs/cards_tab.dart';
import 'tabs/settings_tab.dart';

/// Kilit açıldıktan sonra görünen ana iskelet: üst bar + 3 sekmeli alt çubuk.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titles = ['KARTLARIM', 'KART EKLE', 'AYARLAR'];

  static const _tabs = [
    WalletTab(
      label: 'Kartlarım',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
    ),
    WalletTab(
      label: 'Kart Ekle',
      icon: Icons.add_card_outlined,
      selectedIcon: Icons.add_card,
    ),
    WalletTab(
      label: 'Ayarlar',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Arka plan, şeffaf alt sekme çubuğunun altında da devam etsin.
      extendBody: true,
      // Kartlarım'da üst bar yok: büyük başlık ve kilit butonu sekmenin içinde.
      appBar: _index == 0
          ? null
          : AppBar(
              title: Text(_titles[_index]),
              actions: [
                IconButton(
                  tooltip: 'Kilitle',
                  icon: const Icon(Icons.lock_outline),
                  onPressed: AppScope.of(context).onLock,
                ),
              ],
            ),
      body: AppBackground(
        child: SafeArea(
          // IndexedStack: sekmeler arası geçişte kaydırma konumu vb. korunur.
          child: IndexedStack(
            index: _index,
            children: [
              const CardsTab(),
              // Kart kaydedilince yeni kartı görmek için Kartlarım'a geçilir.
              AddCardTab(onSaved: () => setState(() => _index = 0)),
              const SettingsTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: WalletTabBar(
        key: const ValueKey('wallet_tab_bar'),
        tabs: _tabs,
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}
