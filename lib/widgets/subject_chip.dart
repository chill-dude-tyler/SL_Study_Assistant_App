// FILE: lib/widgets/subject_chip.dart
import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class SubjectChip extends StatelessWidget {
  final String subject;
  final bool small;

  const SubjectChip({super.key, required this.subject, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getSubjectColor(subject);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Text(
        subject,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
