import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:promsell_pos_ce/core/extensions/l10n_extension.dart';
import 'package:promsell_pos_ce/features/settings/presentation/widgets/shared/responsive_settings_picker.dart';

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
      child: DropdownButton<String>(
        value: 'Rp',
        isExpanded: true,
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          DropdownMenuItem(value: 'Rp', child: Text('Rp (IDR)')),
        ],
        onChanged: (v) {
          if (v != null) {
            HapticFeedback.selectionClick();
            onChanged(v);
          }
        },
      ),
    );
  }
}
