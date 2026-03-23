import 'package:flutter/material.dart';

class AsystentUrlopowScreen extends StatelessWidget {
  const AsystentUrlopowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Asystent planowania urlopów",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              ListTile(
                title: Text("Dostępne dni urlopu"),
                subtitle: Text("18 dni"),
              ),
              ListTile(
                title: Text("Zaplanowane urlopy"),
                subtitle: Text("5 dni"),
              ),
              ListTile(
                title: Text("Pozostało"),
                subtitle: Text("13 dni"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}