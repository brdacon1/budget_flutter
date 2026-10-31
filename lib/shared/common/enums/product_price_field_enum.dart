/// Identifica qual campo do formulário de produto/serviço está selecionado.
///
/// Usado pelo [ProductPriceCreatorViewModel] e pelos componentes de
/// `product_price_creator` para destacar o campo focado. Mantido em
/// `common/enums` (e não solto na View/ViewModel) para ser reutilizável e
/// independente da tela — seguindo o padrão de `singup_field_enum.dart`.
enum ProductPriceFieldType {
  categoria,
  unidade,
  preco,
  qtd,
  descricao,
}
