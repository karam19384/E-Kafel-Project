import 'package:flutter/material.dart';

/// خيارات ثابتة (عدِّل كما تريد)
const List<String> kFunctionalLodgmentOptions = <String>[
  'رئيس قسم الكفالة',
  'مشرف ميداني', 
  'محاسب',
  'مدير نظام',
];

const List<String> kAreasOptions = <String>[
  'الشمال',
  'غزة',
  'الوسطى',
  'خان يونس',
  'رفح',
];

/// تُرجع القيمة إن كانت ضمن العناصر، وإلا null لمنع Assert
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

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.toSet().toList();

    return DropdownButtonFormField<String>(
      value: safeDropdownValue(value, uniqueItems),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: uniqueItems
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator ?? // إضافة الـ validator
          (v) {
            if (v == null || v.isEmpty) return 'اختر $label';
            return null;
          },
    );
  }
}