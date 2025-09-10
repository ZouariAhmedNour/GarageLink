import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/mouvement.dart';
import 'package:garagelink/providers/mouvement_provider.dart';
import 'mouvement_form.dart';
import 'package:get/get.dart';

class MouvementsScreen extends ConsumerWidget {
  const MouvementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mouvements = ref.watch(mouvementProvider);

    return Scaffold(
appBar: CustomAppBar(
  title: 'Historique des mouvements',
  backgroundColor: const Color(0xFF357ABD), 
),      body: ListView.separated(
        itemCount: mouvements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = mouvements.reversed.toList()[index];
          return ListTile(
            leading: Icon(
              m.type == TypeMouvement.entree
                  ? Icons.arrow_downward
                  : m.type == TypeMouvement.sortie
                  ? Icons.arrow_upward
                  : Icons.sync,
            ),
            title: Text('${m.type.name} • ${m.quantite}'),
            subtitle: Text(
              '${m.date.toLocal().toString().substring(0, 16)}\n${m.refDoc ?? ''}'
                  .trim(),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(
                () => MouvementFormScreen(
                  mouvement: m,
                  index: mouvements.indexOf(m),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const MouvementFormScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
