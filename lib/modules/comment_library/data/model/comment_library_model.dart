/// Comentário reutilizável da biblioteca do usuário.
///
/// Chaves persistidas fixas (Regra Zero do i18n): `NOME`, `TEXTO`,
/// `CRIADOEM`, `ATUALIZADOEM`.
class CommentLibraryModel {
  final String? id;
  final String name;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommentLibraryModel({
    this.id,
    required this.name,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentLibraryModel.fromMap(Map<String, dynamic> map) =>
      CommentLibraryModel(
        id: map['id'] as String?,
        name: map['NOME'] as String? ?? '',
        text: map['TEXTO'] as String? ?? '',
        createdAt: map['CRIADOEM'] as DateTime?,
        updatedAt: map['ATUALIZADOEM'] as DateTime?,
      );

  Map<String, dynamic> toMap() => {'NOME': name, 'TEXTO': text};

  CommentLibraryModel copyWith({String? id, String? name, String? text}) =>
      CommentLibraryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        text: text ?? this.text,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
