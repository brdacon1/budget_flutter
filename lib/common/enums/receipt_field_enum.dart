/// Identifica qual campo do formulário de recibo está selecionado.
///
/// Usado pelo [ReceiptCreatorViewModel] e pelos componentes de
/// `receipt_creator` para destacar o campo focado. Mantido em `common/enums`
/// (e não solto na View/ViewModel) para ser reutilizável e independente da
/// tela — seguindo o padrão de `product_price_field_enum.dart` e
/// `singup_field_enum.dart`.
enum ReceiptFieldType {
  descricao,
}
