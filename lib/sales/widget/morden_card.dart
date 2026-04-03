import 'package:flutter/material.dart';

class CommonModernCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  final Widget? leading;

  // Instead of trailing, we use dropdown actions
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommonModernCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // main content
          Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 14),

              // Title / Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dropdown area
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<String>(
              underline: SizedBox(),
              hint: Text("More Options"),
              items: [
                DropdownMenuItem(value: "edit", child: Text("Edit")),
                DropdownMenuItem(value: "delete", child: Text("Delete")),
              ],
              onChanged: (value) {
                if (value == "edit" && onEdit != null) onEdit!();
                if (value == "delete" && onDelete != null) onDelete!();
              },
            ),
          ),
        ],
      ),
    );
  }
}
