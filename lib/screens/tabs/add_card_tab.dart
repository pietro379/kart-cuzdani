import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../models/card_model.dart';
import '../../theme/card_swatches.dart';
import '../../theme/wallet_palette.dart';
import '../../utils/card_input_formatters.dart';
import '../../utils/card_number_format.dart';
import '../../utils/card_validators.dart';
import '../../utils/text_format.dart';
import '../../widgets/card_back_view.dart';
import '../../widgets/credit_card_view.dart';
import '../../widgets/flip_card.dart';

/// Yeni kart ekleme formu: canlı önizleme + renk paleti + doğrulamalı alanlar.
class AddCardTab extends StatefulWidget {
  const AddCardTab({super.key, this.onSaved, this.initialCard});

  /// Kart başarıyla kaydedildikten sonra çağrılır (örn. Kartlarım'a geçmek için).
  final VoidCallback? onSaved;

  /// Doluysa form bu kartı düzenler; kaydedince yeni kart eklemek yerine günceller.
  final CardModel? initialCard;

  @override
  State<AddCardTab> createState() => _AddCardTabState();
}

class _AddCardTabState extends State<AddCardTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _pin = TextEditingController();

  // CVV veya şifre yazılırken önizleme kartın arka yüzünü gösterir.
  final _cvvFocus = FocusNode();
  final _pinFocus = FocusNode();

  String _backgroundId = CardSwatches.defaultBackgroundId;
  String _accentId = CardSwatches.defaultAccentId;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _saving = false;
  bool _showSecrets = false;

  bool get _showBack => _cvvFocus.hasFocus || _pinFocus.hasFocus;

  bool get _isEditing => widget.initialCard != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCard;
    if (initial != null) {
      _name.text = initial.name;
      _number.text = formatCardNumber(initial.number, masked: false);
      _expiry.text = initial.expiryText;
      _cvv.text = initial.cvv;
      _pin.text = initial.pin ?? '';
      _backgroundId = initial.backgroundId;
      _accentId = initial.accentId;
    }
    _cvvFocus.addListener(_onFocusChanged);
    _pinFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_name, _number, _expiry, _cvv, _pin]) {
      c.dispose();
    }
    _cvvFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  CardBrand get _brand => detectCardBrand(_number.text);

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    final (month, year) = parseExpiry(_expiry.text)!;
    final card = CardModel(
      id: widget.initialCard?.id ?? CardModel.generateId(),
      name: _name.text.trim(),
      number: digitsOnly(_number.text),
      expiryMonth: month,
      expiryYear: year,
      cvv: _cvv.text,
      pin: _pin.text.isEmpty ? null : _pin.text,
      backgroundId: _backgroundId,
      accentId: _accentId,
      createdAt: widget.initialCard?.createdAt ?? DateTime.now(),
    );

    final cards = AppScope.of(context).cards;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await cards.update(card);
      } else {
        await cards.add(card);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Kart kaydedilemedi, tekrar deneyin.')),
      );
      return;
    }
    if (!mounted) return;

    if (_isEditing) {
      messenger.showSnackBar(
        SnackBar(content: Text('"${card.name}" güncellendi')),
      );
      widget.onSaved?.call();
      return;
    }

    // Hassas veriler kaydedildikten sonra formda bekletilmez.
    for (final c in [_name, _number, _expiry, _cvv, _pin]) {
      c.clear();
    }
    form.reset();
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = false;
      _showSecrets = false;
      _backgroundId = CardSwatches.defaultBackgroundId;
      _accentId = CardSwatches.defaultAccentId;
      _autovalidate = AutovalidateMode.disabled;
    });
    messenger.showSnackBar(
      SnackBar(content: Text('"${card.name}" şifrelenerek kaydedildi')),
    );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppScope.of(context).settings;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      // Önizleme formun üstünde sabit kalır; alanlar kaydırılırken kart görünür.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _name,
                _number,
                _expiry,
                _cvv,
                _pin,
                settings,
              ]),
              builder: (context, _) {
                final background = CardSwatches.background(_backgroundId);
                String secret(String value, String placeholder) => value.isEmpty
                    ? placeholder
                    : _showSecrets
                    ? value
                    : '*' * value.length;
                return FlipCard(
                  flipped: _showBack,
                  front: CreditCardView(
                    background: background,
                    accent: CardSwatches.accent(_accentId),
                    brand: _brand,
                    name: _name.text.trim().isEmpty
                        ? 'Kart İsmi'
                        : _name.text.trim(),
                    numberText: _number.text.isEmpty
                        ? '•••• •••• •••• ••••'
                        : formatCardNumber(_number.text, masked: false),
                    expiryText: _expiry.text.isEmpty ? 'AA/YY' : _expiry.text,
                    holderName: settings.userName.isEmpty
                        ? 'KART SAHİBİ'
                        : turkishUpperCase(settings.userName),
                  ),
                  back: CardBackView(
                    background: background,
                    brand: _brand,
                    cvvText: secret(_cvv.text, '•' * _brand.cvvLength),
                    pinText: _pin.text.isEmpty ? null : secret(_pin.text, ''),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('add_card_list'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const _SectionLabel('KART RENGİ'),
                _SwatchPalette(
                  keyPrefix: 'bg',
                  gradients: CardSwatches.backgroundGradients,
                  solids: CardSwatches.backgroundSolids,
                  selectedId: _backgroundId,
                  onSelected: (id) => setState(() => _backgroundId = id),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('DESEN RENGİ'),
                _SwatchPalette(
                  keyPrefix: 'accent',
                  gradients: CardSwatches.accentGradients,
                  solids: CardSwatches.accentSolids,
                  selectedId: _accentId,
                  onSelected: (id) => setState(() => _accentId = id),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('KART BİLGİLERİ'),
                TextFormField(
                  key: const ValueKey('add_card_name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: CardValidators.maxNameLength,
                  decoration: const InputDecoration(
                    labelText: 'Kart İsmi',
                    hintText: 'Örn. Maaş Kartı',
                    prefixIcon: Icon(Icons.label_outline),
                    counterText: '',
                  ),
                  validator: CardValidators.name,
                ),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: _number,
                  builder: (context, _) => _SensitiveField(
                    fieldKey: const ValueKey('add_card_number'),
                    controller: _number,
                    label: 'Kart Numarası',
                    hint: '0000 0000 0000 0000',
                    icon: Icons.credit_card,
                    formatters: [CardNumberInputFormatter()],
                    validator: CardValidators.number,
                    suffix: _brand == CardBrand.unknown
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Text(
                              _brand.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SensitiveField(
                        fieldKey: const ValueKey('add_card_expiry'),
                        controller: _expiry,
                        label: 'Son Kul. Tarihi',
                        hint: 'AA/YY',
                        icon: Icons.event_outlined,
                        formatters: [ExpiryDateInputFormatter()],
                        validator: CardValidators.expiry,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _number,
                        builder: (context, _) => _SensitiveField(
                          fieldKey: const ValueKey('add_card_cvv'),
                          controller: _cvv,
                          focusNode: _cvvFocus,
                          label: 'CVV',
                          hint: _brand.cvvLength == 4 ? '••••' : '•••',
                          icon: Icons.password,
                          obscure: !_showSecrets,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_brand.cvvLength),
                          ],
                          validator: (v) => CardValidators.cvv(v, _brand),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SensitiveField(
                  fieldKey: const ValueKey('add_card_pin'),
                  controller: _pin,
                  focusNode: _pinFocus,
                  label: 'Kart Şifresi (isteğe bağlı)',
                  hint: '4-6 hane',
                  icon: Icons.pin_outlined,
                  obscure: !_showSecrets,
                  textInputAction: TextInputAction.done,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: CardValidators.pin,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showSecrets = !_showSecrets),
                    icon: Icon(
                      _showSecrets
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _showSecrets
                          ? 'CVV ve şifreyi gizle'
                          : 'CVV ve şifreyi göster',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SaveButton(
                  saving: _saving,
                  editing: _isEditing,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Bilgiler şifrelenerek yalnızca bu cihazda saklanır.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Yatayda kaydırılabilir renk paleti: önce gradyanlar, ince bir ayırıcı,
/// ardından düz renkler.
class _SwatchPalette extends StatelessWidget {
  const _SwatchPalette({
    required this.keyPrefix,
    required this.gradients,
    required this.solids,
    required this.selectedId,
    required this.onSelected,
  });

  /// Test anahtarları için: `bg_neon`, `accent_ac_white` gibi.
  final String keyPrefix;
  final List<CardSwatch> gradients;
  final List<CardSwatch> solids;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return SizedBox(
      height: 84,
      child: ListView(
        key: ValueKey('${keyPrefix}_palette'),
        scrollDirection: Axis.horizontal,
        // Kenarlardaki seçim parıltısı kesilmesin
        clipBehavior: Clip.none,
        children: [
          for (final swatch in gradients) _swatch(swatch),
          // Gradyan | düz renk ayırıcısı
          Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 26),
            child: Center(
              child: Container(width: 1, height: 36, color: outline),
            ),
          ),
          for (final swatch in solids) _swatch(swatch),
        ],
      ),
    );
  }

  Widget _swatch(CardSwatch swatch) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: _SwatchButton(
      key: ValueKey('${keyPrefix}_${swatch.id}'),
      swatch: swatch,
      selected: swatch.id == selectedId,
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(swatch.id);
      },
    ),
  );
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    super.key,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final CardSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: swatch.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        // Sabit genişlik: isim uzunluğu aralıkları bozmasın.
        child: SizedBox(
          width: 60,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatch.isGradient ? null : swatch.colors.single,
                  gradient: swatch.isGradient
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: swatch.colors,
                        )
                      : null,
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: context.palette.glow,
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(Icons.check, color: swatch.foreground)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                swatch.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kart verisi alanları: klavyenin öğrenmesi, öneriler ve otomatik
/// düzeltme kapalı (Android'de gizli/incognito klavye modu).
class _SensitiveField extends StatelessWidget {
  const _SensitiveField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.formatters,
    required this.validator,
    this.obscure = false,
    this.suffix,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String> validator;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      inputFormatters: formatters,
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        letterSpacing: 1.4,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minHeight: 0),
      ),
      validator: validator,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.editing,
    required this.onPressed,
  });

  final bool saving;
  final bool editing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: palette.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.glow, blurRadius: 20)],
      ),
      child: FilledButton.icon(
        key: const ValueKey('add_card_save'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: scheme.onPrimary,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: onPressed,
        icon: saving
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            : const Icon(Icons.lock_outline),
        label: Text(
          editing ? 'DEĞİŞİKLİKLERİ KAYDET' : 'KARTI ŞİFRELE VE KAYDET',
        ),
      ),
    );
  }
}
