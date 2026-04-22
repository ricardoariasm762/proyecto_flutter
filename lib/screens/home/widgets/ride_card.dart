import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';

class RideCard extends StatelessWidget {
  const RideCard({
    required this.ride,
    required this.members,
    required this.seatsLeft,
    required this.totalFare,
    required this.splitFare,
    this.onOpenDetails,
    this.onJoin,
    this.onOpenChat,
    this.onRate,
    super.key,
  });

  final Map<String, dynamic> ride;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenChat;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;

    final oLat = (ride['origin_lat'] as num?)?.toDouble();
    final oLng = (ride['origin_lng'] as num?)?.toDouble();
    final dLat = (ride['dest_lat'] as num?)?.toDouble();
    final dLng = (ride['dest_lng'] as num?)?.toDouble();
    final status = (ride['status'] ?? 'waiting').toString();
    final statusRaw = status.toLowerCase();
    
    final isPending = statusRaw == 'pending' || statusRaw == 'esperando usuario';
    final isActive = statusRaw == 'active' || statusRaw == 'en viaje';
    
    final statusLabel = isPending
        ? AppDictionary.text(lang, 'waiting_user')
        : (isActive ? AppDictionary.text(lang, 'on_trip') : AppDictionary.text(lang, 'available'));
        
    final statusFg = isPending
        ? const Color(0xFFE65100)
        : (isActive ? const Color(0xFF1B5E20) : const Color(0xFF6B42C7));
    final statusBg = isPending
        ? const Color(0xFFFFE0B2)
        : (isActive ? const Color(0xFFC8E6C9) : const Color(0x1A6D3FD1));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPending ? const Color(0xFFFFE0B2) : Theme.of(context).colorScheme.outlineVariant,
              width: isPending ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isPending
                        ? const Color(0xFFFFF3E0)
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      isPending ? Icons.hourglass_top_rounded : Icons.route,
                      color: isPending
                          ? const Color(0xFFE65100)
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${AppDictionary.text(lang, 'route')} #${ride['id'] ?? '--'}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "${AppDictionary.text(lang, 'origin')}: ${(oLat ?? 0).toStringAsFixed(4)}, ${(oLng ?? 0).toStringAsFixed(4)}",
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                "${AppDictionary.text(lang, 'destination')}: ${(dLat ?? 0).toStringAsFixed(4)}, ${(dLng ?? 0).toStringAsFixed(4)}",
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$members/5 ${AppDictionary.text(lang, 'people')} • ${AppDictionary.text(lang, 'seats')}: $seatsLeft",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${AppDictionary.text(lang, 'total')}: \$${totalFare.toStringAsFixed(0)} • ${AppDictionary.text(lang, 'split')}: \$${splitFare.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (onOpenChat != null)
                        OutlinedButton.icon(
                          onPressed: onOpenChat,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: Text(AppDictionary.text(lang, 'chat')),
                        ),
                      if (onRate != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: onRate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade700,
                            side: BorderSide(color: Colors.amber.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          icon: const Icon(Icons.star_rounded, size: 16),
                          label: Text(AppDictionary.text(lang, 'rate')),
                        ),
                      ],
                      if (!isPending && onJoin != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: Text(AppDictionary.text(lang, 'join')),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
