// lib/src/utils/dropdown_utils_extended.dart
import 'package:flutter/material.dart';

class DropdownHelper {
  static DropdownButtonFormField<String> createSafeDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool isExpanded = true,
  }) {
    // تحقق من التكرارات في القيم
    final values = items.map((e) => e.value).whereType<String>().toList();
    final uniqueValues = values.toSet().toList();
    
    if (values.length != uniqueValues.length) {
      debugPrint('تحذير: هناك تكرار في قيم Dropdown - $label');
      // استخدم القيم الفريدة فقط
      final uniqueItems = <DropdownMenuItem<String>>[];
      final seenValues = <String>{};
      
      for (final item in items) {
        if (item.value != null && !seenValues.contains(item.value)) {
          seenValues.add(item.value!);
          uniqueItems.add(item);
        }
      }
      items = uniqueItems;
    }

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// إنشاء قائمة DropdownMenuItem من قائمة النصوص
  static List<DropdownMenuItem<String>> createMenuItems(List<String> options) {
    return options
        .map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ))
        .toList();
  }

  /// التحقق من قيمة آمنة للدروب داون
  static String? getSafeValue(String? value, List<String> options) {
    if (value == null || value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }
}