import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GlassCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: .2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Leading icon (if any)
              if (leading != null) ...[leading!, const SizedBox(width: 12)],

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min, // ← Important for compact height
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: .8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // More options menu
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  color: Colors.white.withValues(alpha: .15),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: .2)),
                  ),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withValues(alpha: .9),
                    size: 20,
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Text(
                        "Edit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text(
                        "Delete",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == "edit") onEdit?.call();
                    if (value == "delete") onDelete?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
