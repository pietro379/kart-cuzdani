import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../widgets/app_background.dart';
import 'tabs/add_card_tab.dart';

/// Kayıtlı bir kartı düzenleme ekranı: Kart Ekle formunun dolu hali.
class EditCardScreen extends StatelessWidget {
  const EditCardScreen({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('KARTI DÜZENLE')),
      body: AppBackground(
        child: SafeArea(
          child: AddCardTab(
            initialCard: card,
            onSaved: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
