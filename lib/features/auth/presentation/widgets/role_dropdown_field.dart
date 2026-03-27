import 'package:flutter/material.dart';
import 'package:mobile/features/auth/domain/public_user_role.dart';

class RoleDropdownField extends StatelessWidget {
  const RoleDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final PublicUserRole? value;
  final ValueChanged<PublicUserRole?> onChanged;
  final String? Function(PublicUserRole?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PublicUserRole>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Role',
        hintText: 'Select a role',
      ),
      validator: validator,
      items: PublicUserRole.values.map((role) {
        return DropdownMenuItem<PublicUserRole>(
          value: role,
          child: Text(role.label),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
