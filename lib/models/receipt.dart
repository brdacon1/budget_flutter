/// Model de **recibo** (compartilhado entre as features de recibo, pagamento
/// e PDF).
///
/// Migração do model legado (`fromMap`/`toMap` com campos públicos mutáveis e
/// nomes em `UPPER_CASE`) para o **padrão de model do Flutter** (seção 10 do
/// SDD `.pi/sdd_arquitetura_view_model.md`):
///
/// - construtor `const` com campos `final` (imutável);
/// - `factory fromJson(Map<String, dynamic>)`;
/// - `Map<String, dynamic> toJson()`;
/// - `copyWith({...})`.
///
/// Como é um model **compartilhado entre várias features** (recibo, pagamento,
/// PDF), continua em `lib/models/*` (camada global) — ver seção 10.2 do SDD.
///
/// As **chaves do Firebase** permanecem maiúsculas (`ID`, `DATA`,
/// `DESCRICAO`, `VALORTOTAL`) para não quebrar os documentos já gravados —
/// apenas a nomenclatura Dart muda para `camelCase` (`id`, `data`,
/// `descricao`, `valorTotal`).
///
/// `checkBox` e `indice` são **estado de UI em memória** (não persistidos no
/// Firebase): o `toJson()` mantém só as 4 chaves originais, preservando
/// exatamente o que era gravado antes; o `fromJson()` os lê (quando
/// presentes) ou parte do padrão (`checkBox = null`, `indice = 0`).
class Receipt {
  final String? id;
  final String? data;
  final String? descricao;
  final double? valorTotal;

  // --- Estado de UI (em memória, não persistido) ---
  final bool? checkBox;
  final int indice;

  const Receipt({
    this.id,
    this.data,
    this.descricao,
    this.valorTotal,
    this.checkBox,
    this.indice = 0,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['ID'] as String?,
        data: json['DATA'] as String?,
        descricao: json['DESCRICAO'] as String?,
        valorTotal: _toDouble(json['VALORTOTAL']),
        checkBox: json['checkBox'] as bool?,
        indice: (json['indice'] as int?) ?? 0,
      );

  /// Mantém somente as 4 chaves originais gravadas no Firebase — preserva o
  /// formato dos documentos já existentes (sem introduzir `checkBox`/`indice`).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ID': id,
        'DATA': data,
        'DESCRICAO': descricao,
        'VALORTOTAL': valorTotal,
      };

  Receipt copyWith({
    String? id,
    String? data,
    String? descricao,
    double? valorTotal,
    bool? checkBox,
    int? indice,
  }) {
    return Receipt(
      id: id ?? this.id,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      valorTotal: valorTotal ?? this.valorTotal,
      checkBox: checkBox ?? this.checkBox,
      indice: indice ?? this.indice,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
