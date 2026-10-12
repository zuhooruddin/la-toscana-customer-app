import '../core/models.dart';

/// Selected choice keys per group key.
typedef Selection = Map<String, List<String>>;

/// Max for a group, honouring maxByChoice (e.g. 2 flavours only with "2 bolas").
int effectiveMax(OptionGroup g, Selection sel) {
  final m = g.maxByChoice;
  if (m == null) return g.max;
  final picked = sel[m.groupKey] ?? const [];
  if (picked.isEmpty) return g.max;
  return m.map[picked.first] ?? g.max;
}

/// Toggle a choice: radio behaviour for single-choice groups, capped multi-select otherwise.
Selection toggleChoice(OptionGroup g, Selection sel, String choiceKey) {
  final next = {for (final e in sel.entries) e.key: [...e.value]};
  final current = next[g.key] ?? <String>[];
  final single = g.max == 1 && g.maxByChoice == null;
  if (single) {
    next[g.key] = current.contains(choiceKey) && !g.required && g.min == 0 ? [] : [choiceKey];
  } else if (current.contains(choiceKey)) {
    next[g.key] = current.where((c) => c != choiceKey).toList();
  } else if (current.length < effectiveMax(g, sel)) {
    next[g.key] = [...current, choiceKey];
  }
  return next;
}

/// Drop picks that a changed dependency no longer allows (e.g. back to 1 scoop).
Selection normaliseSelection(MenuItem item, Selection sel) {
  final next = {for (final e in sel.entries) e.key: [...e.value]};
  for (final g in item.optionGroups) {
    final max = effectiveMax(g, next);
    final cur = next[g.key] ?? const [];
    if (cur.length > max) next[g.key] = cur.take(max).toList();
  }
  return next;
}

int unitPrice(MenuItem item, Selection sel) {
  var p = item.priceCents;
  for (final g in item.optionGroups) {
    for (final key in sel[g.key] ?? const <String>[]) {
      for (final c in g.choices) {
        if (c.key == key) p += c.priceDeltaCents;
      }
    }
  }
  return p;
}

/// Lowest price a dish can cost given its required choices (for "desde").
int fromPrice(MenuItem item) {
  var p = item.priceCents;
  for (final g in item.optionGroups.where((g) => g.min > 0)) {
    final deltas = g.choices.where((c) => c.available).map((c) => c.priceDeltaCents).toList()..sort();
    for (var i = 0; i < g.min && i < deltas.length; i++) {
      p += deltas[i];
    }
  }
  return p;
}

/// Groups whose required minimum is not met.
List<OptionGroup> missingGroups(MenuItem item, Selection sel) =>
    item.optionGroups.where((g) => (sel[g.key]?.length ?? 0) < (g.min > 0 ? g.min : (g.required ? 1 : 0))).toList();
