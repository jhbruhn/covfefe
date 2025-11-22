import 'package:flutter/material.dart';

/// Card widget to display a single statistic
class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isCached;

  const StatisticCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onTap,
    this.isCached = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use grey for cached state, otherwise use provided color or primary
    final effectiveIconColor = isCached 
        ? colorScheme.outline 
        : (iconColor ?? colorScheme.primary);
    
    // Opacity for cached state
    final contentOpacity = isCached ? 0.6 : 1.0;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Opacity(
            opacity: contentOpacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: effectiveIconColor,
                    ),
                    if (isCached)
                      Transform.translate(
                        offset: const Offset(8, -8),
                        child: Icon(
                          Icons.history,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
