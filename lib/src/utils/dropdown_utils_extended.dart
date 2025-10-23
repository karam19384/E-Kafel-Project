// lib/src/utils/dropdown_utils_extended.dart
import 'package:flutter/material.dart';

class DropdownHelper {
  /// Dropdown آمن: يزيل التكرارات، ويتحقق أن value ضمن العناصر وإلا يسقطها
  static DropdownButtonFormField<String> createSafeDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool isExpanded = true,
  }) {
    // انسخ القائمة حتى لا تغيّر المرجع الأصلي
    final cloned = List<DropdownMenuItem<String>>.from(items);

    // إزالة التكرارات حسب value مع الحفاظ على أول ظهور
    final seen = <String>{};
    final deduped = <DropdownMenuItem<String>>[];
    for (final item in cloned) {
      final v = item.value;
      if (v == null) continue;
      if (seen.add(v)) deduped.add(item);
    }

    // تحقق من قيمة آمنة
    final values = deduped.map((e) => e.value).whereType<String>().toList();
    final safeVal = getSafeValue(value, values);

    return DropdownButtonFormField<String>(
      value: safeVal,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: deduped,
      onChanged: onChanged,
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'اختر $label';
            return null;
          },
      // تحسين العرض المطوّل
      selectedItemBuilder: (_) => deduped
          .map((e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e.child is Text ? (e.child as Text).data ?? '' : (e.value ?? ''),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
    );
  }

  /// إنشاء عناصر Dropdown من قائمة نصوص
  static List<DropdownMenuItem<String>> createMenuItems(List<String> options) {
    final unique = options.map((e) => e.trim()).toSet().toList();
    return unique
        .map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ))
        .toList();
  }

  /// إنشاء عناصر Dropdown من خريطة value=>label
  static List<DropdownMenuItem<String>> createMenuItemsFromMap(
    Map<String, String> map,
  ) {
    final entries = <MapEntry<String, String>>[];
    final seen = <String>{};
    for (final kv in map.entries) {
      final k = kv.key.trim();
      if (k.isEmpty || !seen.add(k)) continue;
      entries.add(MapEntry(k, kv.value));
    }
    return entries
        .map((e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ))
        .toList();
  }

  /// التحقق من قيمة آمنة للدروب داون
  static String? getSafeValue(String? value, List<String> options) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return options.contains(v) ? v : null;
  }

  /// ودجت جاهز: Dropdown + حقل "أخرى" اختياري
  static Widget dropdownWithOther({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    TextEditingController? otherController,
    String otherLabel = 'أخرى',
    String? Function(String?)? validator,
  }) {
    final withOther = [...options.map((e) => e.trim()), if (!options.contains(otherLabel)) otherLabel];
    final items = createMenuItems(withOther);

    final showOther = value == otherLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        createSafeDropdown(
          label: label,
          value: value,
          items: items,
          onChanged: (v) {
            onChanged(v);
            // امسح حقل "أخرى" عند التبديل
            if (v != otherLabel && otherController != null) {
              otherController.clear();
            }
          },
          validator: validator,
        ),
        if (showOther && otherController != null) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: otherController,
            decoration: InputDecoration(
              labelText: 'أدخل $label',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit),
            ),
            validator: (v) {
              if (value == otherLabel) {
                if (v == null || v.trim().isEmpty) return 'أدخل $label';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

/// خيارات ثابتة (عدِّل كما تريد)
const List<String> kFunctionalLodgmentOptions = <String>[
  'رئيس قسم الكفالة',
  'مشرف ميداني',
  'أخرى',
];

const List<String> kAreasOptions = <String>[
  'الشمال',
  'غزة',
  'الوسطى',
  'خان يونس',
  'رفح',
  'أخرى',
];

/// تُرجع القيمة إن كانت ضمن العناصر، وإلا null لمنع مشاكل القيمة
T? safeDropdownValue<T>(T? value, List<T> items) {
  if (value == null) return null;
  return items.contains(value) ? value : null;
}

class LabeledDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final bool isExpanded;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.map((e) => e.trim()).toSet().toList();
    final safeVal = DropdownHelper.getSafeValue(value, uniqueItems);

    return DropdownButtonFormField<String>(
      value: safeVal,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: uniqueItems
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'اختر $label';
            return null;
          },
      selectedItemBuilder: (_) => uniqueItems
          .map((e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
    );
  }
}
