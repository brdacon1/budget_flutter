/// Identifica qual campo do formulário de cadastro está selecionado.
///
/// Usado pelo [SingUpViewModel] e pelos componentes de `singup` para destacar o
/// campo focado e colorir ícones/hint. Mantido em `common/enums` para ser
/// reutilizável e independente da View.
enum SingUpFieldType {
  name,
  email,
  password,
  confirmPassword,
  phone,
}
