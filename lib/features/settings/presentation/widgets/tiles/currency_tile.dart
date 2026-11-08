import 'package:flutter/material.dart';
import 'package:promsell_pos_ce/core/extensions/l10n_extension.dart';
import 'package:promsell_pos_ce/features/settings/presentation/widgets/shared/responsive_settings_picker.dart';

// ignore: must_be_immutable
class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ResponsiveSettingsPicker(
      icon: Icons.attach_money,
      title: context.l10n.settingsCurrency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'Rp (IDR)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
