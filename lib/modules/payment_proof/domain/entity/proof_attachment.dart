import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';

/// Arquivo local escolhido para virar comprovante (ainda não enviado).
class ProofAttachment {
  final String path;
  final String name;
  final PaymentProofType type;
  final int size;

  const ProofAttachment({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
  });

  bool get isPdf => type == PaymentProofType.pdf;

  Map<String, dynamic> toPayload() => {
    'path': path,
    'name': name,
    'type': type.value,
    'size': size,
  };

  factory ProofAttachment.fromPayload(Map<String, dynamic> map) =>
      ProofAttachment(
        path: map['path'] as String,
        name: map['name'] as String? ?? '',
        type: PaymentProofType.fromValue(map['type'] as String?),
        size: (map['size'] as num?)?.toInt() ?? 0,
      );
}
