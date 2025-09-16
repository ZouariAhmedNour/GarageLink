import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumeroSerieInput extends StatefulWidget {
  final TextEditingController vinCtrl;
  final TextEditingController numLocalCtrl;
  final ValueChanged<String>? onChanged;

  const NumeroSerieInput({
    super.key,
    required this.vinCtrl,
    required this.numLocalCtrl,
    this.onChanged,
  });

  @override
  State<NumeroSerieInput> createState() => _NumeroSerieInputState();
}

class _NumeroSerieInputState extends State<NumeroSerieInput> {
  bool isLocal = true;

  // contrôleurs pour les 2 parties de l'immatriculation locale
  late final TextEditingController _avantCtrl;
  late final TextEditingController _apresCtrl;

  // listeners pour synchroniser quand parent modifie les controllers
  VoidCallback? _numLocalListener;
  VoidCallback? _vinListener;

  @override
  void initState() {
    super.initState();

    // initialiser les controllers locaux en se basant sur numLocalCtrl s'il contient déjà une valeur
    final initialLocal = widget.numLocalCtrl.text.trim();
    final parsed = _parseLocal(initialLocal);
    _avantCtrl = TextEditingController(text: parsed['avant']);
    _apresCtrl = TextEditingController(text: parsed['apres']);

    // listeners internes -> mise à jour du controller parent
    _avantCtrl.addListener(_updateLocalValue);
    _apresCtrl.addListener(_updateLocalValue);

    // si parent change numLocalCtrl ou vinCtrl (ex: reset depuis l'extérieur), on met à jour
    _numLocalListener = () {
      final parsed = _parseLocal(widget.numLocalCtrl.text.trim());
      if (_avantCtrl.text != parsed['avant']) _avantCtrl.text = parsed['avant'] ?? '';
      if (_apresCtrl.text != parsed['apres']) _apresCtrl.text = parsed['apres'] ?? '';
    };
    widget.numLocalCtrl.addListener(_numLocalListener!);

    _vinListener = () {
      // si parent modifie le vin, on déclenche onChanged aussi (utile)
      widget.onChanged?.call(widget.vinCtrl.text);
    };
    widget.vinCtrl.addListener(_vinListener!);

    // déterminer si on affiche local ou foreign en se basant sur les valeurs présentes
    if (widget.vinCtrl.text.trim().isNotEmpty && widget.numLocalCtrl.text.trim().isEmpty) {
      isLocal = false;
    } else if (widget.numLocalCtrl.text.trim().isNotEmpty) {
      isLocal = true;
    }
  }

  @override
  void dispose() {
    _avantCtrl.removeListener(_updateLocalValue);
    _apresCtrl.removeListener(_updateLocalValue);
    _avantCtrl.dispose();
    _apresCtrl.dispose();

    if (_numLocalListener != null) widget.numLocalCtrl.removeListener(_numLocalListener!);
    if (_vinListener != null) widget.vinCtrl.removeListener(_vinListener!);

    super.dispose();
  }

  /// Parse une immatriculation locale du format "<avant>TUN<apres>" en parties
  Map<String?, String?> _parseLocal(String value) {
    if (value.isEmpty) return {'avant': '', 'apres': ''};
    final up = value.toUpperCase();
    if (up.contains('TUN')) {
      final parts = up.split('TUN');
      final avant = parts.isNotEmpty ? parts[0].replaceAll(RegExp(r'[^0-9]'), '') : '';
      final apres = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '';
      return {'avant': avant, 'apres': apres};
    }
    // si pas de TUN, essayer d'assigner tout à apres (ou à avant)
    return {'avant': '', 'apres': up.replaceAll(RegExp(r'[^0-9]'), '')};
  }

  void _updateLocalValue() {
    final avant = _avantCtrl.text.trim();
    final apres = _apresCtrl.text.trim();
    final built = '${avant}TUN${apres}';
    // Mettre à jour le controller parent sans re-déclencher boucle infinie (le listener parent est idempotent)
    if (widget.numLocalCtrl.text != built) {
      widget.numLocalCtrl.text = built;
    }
    widget.onChanged?.call(widget.numLocalCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Local / Étranger
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.location_on, color: Color(0xFF4A90E2)),
                label: const Text("Local"),
                selected: isLocal,
                onSelected: (_) {
                  setState(() => isLocal = true);
                  // Si on passe à local et parent a déjà une immatriculation locale, on la parse (déjà géré par listener)
                  _updateLocalValue();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.language, color: Color(0xFF4A90E2)),
                label: const Text("Étranger"),
                selected: !isLocal,
                onSelected: (_) {
                  setState(() => isLocal = false);
                  // Propager l'état actuel du VIN au callback si existant
                  widget.onChanged?.call(widget.vinCtrl.text);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isLocal)
          Row(
            children: [
              // Partie avant (chiffres)
              Expanded(
                child: TextFormField(
                  controller: _avantCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "ex '250' ",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                  validator: (v) {
                    // pas obligatoire globalement : le parent vérifiera si aucun champ n'est rempli
                    return null;
                  },
                ),
              ),
              // TUN fixe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                color: Colors.blue[900],
                child: const Text(
                  "TUN",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              // Partie après (chiffres)
              Expanded(
                child: TextFormField(
                  controller: _apresCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "ex: '1999' ",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  validator: (v) {
                    return null;
                  },
                ),
              ),
            ],
          )
        else
          TextFormField(
            controller: widget.vinCtrl,
            decoration: const InputDecoration(
              labelText: "N° de série (étranger)",
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? "Obligatoire" : null,
            onChanged: (v) => widget.onChanged?.call(v),
          ),
      ],
    );
  }
}
