import 'package:flutter/material.dart';

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

  String _avant = "";
  String _apres = "";

  void _updateLocalValue() {
    widget.numLocalCtrl.text = "${_avant}TUN${_apres}";
     widget.onChanged?.call(widget.numLocalCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.location_on, color: Color(0xFF4A90E2)),
                label: const Text("Local"),
                selected: isLocal,
                onSelected: (_) => setState(() => isLocal = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.language, color: Color(0xFF4A90E2)),
                label: const Text("Étranger"),
                selected: !isLocal,
                onSelected: (_) => setState(() => isLocal = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isLocal)
          Row(
            children: [
              // Partie avant TUN
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "ex '250' ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    _avant = v;
                    _updateLocalValue();
                  },
                ),
              ),
              // TUN fixe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                color: Colors.grey.shade200,
                child: const Text(
                  "TUN",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Partie après TUN
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "ex: '1999' ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    _apres = v;
                    _updateLocalValue();
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