import 'package:flutter/material.dart';

enum ModulAplikacji {
  kalendarz,
  obecnosci,
  urlopy,
}

class ModulyNavigationBar extends StatelessWidget {
  const ModulyNavigationBar({
    super.key,
    required this.aktualnyModul,
    required this.onZmianaModulu,
  });

  final ModulAplikacji aktualnyModul;
  final ValueChanged<ModulAplikacji> onZmianaModulu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          _button(context, ModulAplikacji.kalendarz, "Kalendarz:)"),
          _button(context, ModulAplikacji.obecnosci, "Obecności"),
          _button(context, ModulAplikacji.urlopy, "Urlopy"),
        ],
      ),
    );
  }

  Widget _button(
      BuildContext context, ModulAplikacji modul, String label) {
    final selected = modul == aktualnyModul;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () => onZmianaModulu(modul),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}