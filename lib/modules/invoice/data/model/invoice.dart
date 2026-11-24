import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';

/// Nota fiscal / recibo de compra vinculado a um orçamento.
///
/// `ORCAMENTOS/{budgetId}/NOTASFISCAIS/{id}`. Valor a cobrar do cliente —
/// **não** entra no total do orçamento.
class Invoice {
  final String id;
  final String name;
  final double value;
  final PaymentProofType type;
  final String fileUrl;
  final String storagePath;
  final int size;
  final DateTime createdAt;
  final String origin;

  const Invoice({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
    required this.fileUrl,
    required this.storagePath,
    required this.size,
    required this.createdAt,
    required this.origin,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final raw = json['CRIADOEM'];
    final createdAt = switch (raw) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['id']?.toString() ?? '') ?? 0,
      ),
    };
    return Invoice(
      id: json['id']?.toString() ?? '',
      name: json['NOME'] as String? ?? '',
      value: (json['VALOR'] as num?)?.toDouble() ?? 0,
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
    'TIPO': type.value,
    'ARQUIVO': fileUrl,
    'CAMINHO': storagePath,
    'TAMANHO': size,
    'CRIADOEM': Timestamp.fromDate(createdAt),
    'ORIGEM': origin,
  };

  /// Mesma forma do comprovante: reaproveita card, detalhe e visualizador.
  PaymentProof toProof() => PaymentProof(
    id: id,
    name: name,
    value: value,
    type: type,
    fileUrl: fileUrl,
    storagePath: storagePath,
    size: size,
    createdAt: createdAt,
    origin: origin,
  );
}
