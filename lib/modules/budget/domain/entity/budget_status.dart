/// Status de orçamento. [value] é o valor PERSISTIDO no Firestore — nunca
/// traduzir (Regra Zero do i18n); só o label exibido muda de idioma.
enum BudgetStatus {
  pendente('PENDENTE'),
  aprovado('APROVADO'),
  reprovado('REPROVADO'),
  finalizado('FINALIZADO');

  const BudgetStatus(this.value);

  final String value;

  static BudgetStatus? fromValue(String? value) {
    final v = value?.toUpperCase();
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}
