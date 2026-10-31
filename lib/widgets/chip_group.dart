import 'package:flutter/material.dart';
import 'package:najda/data/constants.dart';

class ChipGroup extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool on) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [noneLabel, ...options]
                .map((o) => FilterChip(
                      label: Text(o),
                      selected: selected.contains(o),
                      onSelected: (on) => onToggle(o, on),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
