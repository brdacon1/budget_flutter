import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Relatório de recibos por período devolvido pela IA. Números (inclusive a
/// variação %) vêm do `GetReceiptsReportUsecase`, nunca do modelo.
///
/// Payload: `title`, `countLabel`, `count`, `issuedLabel`, `issued`,
/// `paidLabel`, `paid`, `previous?`, `change?` (int %),
/// `buckets[{label, count, paid, paidRaw}]`, `topLabel`,
/// `top[{id, name, count, paid}]`. Toque no top → `open_budget|<id>`.
class ChatReceiptsReportCard extends StatelessWidget {
  final Map<String, dynamic> payload;
  final void Function(String action)? onTap;

  const ChatReceiptsReportCard({super.key, required this.payload, this.onTap});

  static const _muted = TextStyle(color: mutedTextColor, fontSize: 12);
  static const _white = TextStyle(color: whiteColor);

  @override
  Widget build(BuildContext context) {
    final buckets =
        (payload['buckets'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    final top =
        (payload['top'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    final maxPaid = buckets.fold<double>(
      0,
      (m, b) =>
          ((b['paidRaw'] as num?) ?? 0) > m
              ? (b['paidRaw'] as num).toDouble()
              : m,
    );
    final change = payload['change'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payload['title'] as String? ?? '',
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _metric(payload['countLabel'], '${payload['count'] ?? 0}'),
            _metric(payload['issuedLabel'], payload['issued']),
            _metric(payload['paidLabel'], payload['paid']),
          ],
        ),
        if (payload['previous'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(payload['previous'] as String, style: _muted),
              ),
              if (change != null)
                Text(
                  '${change >= 0 ? '▲' : '▼'} ${change.abs()}%',
                  style: TextStyle(
                    color:
                        change >= 0 ? statusApprovedColor : statusRejectedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
        if (buckets.length > 1) ...[
          const SizedBox(height: 10),
          for (final b in buckets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(b['label'] as String? ?? '', style: _muted),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value:
                            maxPaid == 0
                                ? 0
                                : ((b['paidRaw'] as num?) ?? 0) / maxPaid,
                        minHeight: 6,
                        backgroundColor: cardBorderColor,
                        color: buttonColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${b['count']}', style: _muted),
                ],
              ),
            ),
        ],
        if (top.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(payload['topLabel'] as String? ?? '', style: _muted),
          for (final t in top)
            InkWell(
              onTap:
                  onTap == null ? null : () => onTap!('open_budget|${t['id']}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t['name']} (${t['count']})',
                        style: _white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(t['paid'] as String? ?? '', style: _white),
                    const Icon(
                      Icons.chevron_right,
                      color: mutedTextColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _metric(Object? label, Object? value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${label ?? ''}', style: _muted),
        Text(
          '${value ?? ''}',
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
