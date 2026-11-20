import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';

/// Comprovante de pagamento vinculado a um orçamento.
///
/// Chaves do Firestore em maiúsculas, iguais ao padrão do app:
/// `ORCAMENTOS/{budgetId}/COMPROVANTES/{id}`.
class PaymentProof {
  final String id;
  final String name;
  final double? value;
  final String? comment;
  final PaymentProofType type;
  final String fileUrl;
  final String storagePath;
  final int size;
  final DateTime createdAt;
  final String origin;

  const PaymentProof({
    required this.id,
    required this.name,
    this.value,
    this.comment,
    required this.type,
    required this.fileUrl,
    required this.storagePath,
    required this.size,
    required this.createdAt,
    required this.origin,
  });

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    final raw = json['CRIADOEM'];
    final createdAt = switch (raw) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ =>
        DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['id']?.toString() ?? '') ?? 0,
        ),
    };
    return PaymentProof(
      id: json['id']?.toString() ?? '',
      name: json['NOME'] as String? ?? '',
      value: (json['VALOR'] as num?)?.toDouble(),
      comment: json['COMENTARIO'] as String?,
      type: PaymentProofType.fromValue(json['TIPO'] as String?),
      fileUrl: json['ARQUIVO'] as String? ?? '',
      storagePath: json['CAMINHO'] as String? ?? '',
      size: (json['TAMANHO'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      origin: json['ORIGEM'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'NOME': name,
    'VALOR': value,
    'COMENTARIO': comment,
    'TIPO': type.value,
    'ARQUIVO': fileUrl,
    'CAMINHO': storagePath,
    'TAMANHO': size,
    'CRIADOEM': Timestamp.fromDate(createdAt),
    'ORIGEM': origin,
  };
}
