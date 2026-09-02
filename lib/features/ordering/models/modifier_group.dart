import 'modifier.dart';

/// A named group of Modifiers with selection rules (e.g. "Milk Type" —
/// required, pick exactly 1; "Extras" — optional, pick up to 3). Maps to
/// the spec's `modifier_groups` + `product_modifier_groups` tables.
///
/// [minSelect] / [maxSelect] define how many modifiers from this group
/// must/can be chosen. [required] is a convenience — a group is
/// effectively required whenever [minSelect] > 0, but keeping it explicit
/// makes the UI logic (and the eventual admin form) easier to reason about.
class ModifierGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool required;
  final List<Modifier> modifiers;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.required = false,
    this.modifiers = const [],
  });

  /// Single-choice groups (maxSelect == 1) behave like radio buttons —
  /// selecting a new option replaces the previous one.
  bool get isSingleChoice => maxSelect == 1;

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        minSelect: json['minSelect'] as int? ?? 0,
        maxSelect: json['maxSelect'] as int? ?? 1,
        required: json['required'] as bool? ?? false,
        modifiers: (json['modifiers'] as List<dynamic>? ?? [])
            .map((e) => Modifier.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minSelect': minSelect,
        'maxSelect': maxSelect,
        'required': required,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };
}
