import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';

/// Ramo de atuação do usuário.
///
/// [value] é o texto gravado no Firestore — fixo, NUNCA traduzir (Regra Zero
/// de i18n). [label] é o texto exibido na tela (pt/en). [none] = o usuário
/// escolheu "Agora não" (não perguntar de novo).
enum BusinessSegment {
  earthworks('terraplanagem'),
  painting('pintura'),
  masonry('alvenaria'),
  other('outro'),
  none('nenhum');

  final String value;
  const BusinessSegment(this.value);

  String get label => switch (this) {
    BusinessSegment.earthworks => ProductPtString.segmentEarthworks,
    BusinessSegment.painting => ProductPtString.segmentPainting,
    BusinessSegment.masonry => ProductPtString.segmentMasonry,
    BusinessSegment.other => ProductPtString.segmentOther,
    BusinessSegment.none => '',
  };

  /// Descrições de referência, no jeito que o profissional cobra (unidade
  /// entre parênteses). Vão no prompt da IA só como modelo de vocabulário;
  /// não são exibidas nem gravadas. Vazio = sem referência.
  List<String> get references => switch (this) {
    BusinessSegment.masonry => const [
      'Levantamento de parede de bloco/tijolo (m²)',
      'Chapisco (m²)',
      'Emboço (m²)',
      'Reboco interno (m²)',
      'Reboco externo (m²)',
      'Contrapiso (m²)',
      'Assentamento de piso cerâmico ou porcelanato (m²)',
      'Assentamento de azulejo/revestimento de parede (m²)',
      'Rejuntamento (m²)',
      'Execução de laje (m²)',
      'Fundação: sapata e baldrame (m)',
      'Concretagem de viga e pilar (m³)',
      'Calçada e piso de concreto (m²)',
      'Muro de bloco (m²)',
      'Impermeabilização (m²)',
      'Demolição de parede (m²)',
      'Reparos e pequenas reformas (vb)',
      'Diária de pedreiro (dia)',
      'Diária de servente (dia)',
    ],
    BusinessSegment.painting => const [
      'Pintura de parede interna com tinta acrílica, 2 demãos (m²)',
      'Pintura de parede externa/fachada (m²)',
      'Pintura de teto (m²)',
      'Aplicação de massa corrida (m²)',
      'Aplicação de massa acrílica em área externa (m²)',
      'Lixamento de parede (m²)',
      'Aplicação de selador (m²)',
      'Textura ou grafiato (m²)',
      'Raspagem de tinta velha ou remoção de papel de parede (m²)',
      'Tratamento de mofo e infiltração (m²)',
      'Correção de trincas e fissuras (m)',
      'Pintura de esmalte em porta ou janela (un)',
      'Pintura de portão ou grade (m²)',
      'Verniz em madeira ou deck (m²)',
      'Pintura de rodapé e batente (m)',
      'Pintura de piso ou garagem (m²)',
      'Proteção e mascaramento (vb)',
      'Diária de pintor (dia)',
      'Diária de ajudante (dia)',
    ],
    BusinessSegment.earthworks => const [
      'Hora de escavadeira hidráulica (h)',
      'Hora de retroescavadeira (h)',
      'Hora de pá carregadeira (h)',
      'Hora de mini carregadeira (h)',
      'Hora de trator de esteira (h)',
      'Hora de motoniveladora (h)',
      'Hora de rolo compactador (h)',
      'Hora de caminhão basculante (h)',
      'Escavação e corte de terra (m³)',
      'Aterro compactado (m³)',
      'Transporte de terra e bota-fora (m³)',
      'Limpeza e destocamento do terreno (m²)',
      'Nivelamento e regularização de terreno (m²)',
      'Abertura de vala (m)',
      'Abertura de acesso ou estrada (m)',
      'Escavação para fundação (m³)',
      'Fornecimento de saibro, cascalho ou material de aterro (m³)',
      'Caminhão pipa (dia)',
      'Mobilização e deslocamento de máquina (vb)',
    ],
    BusinessSegment.other || BusinessSegment.none => const [],
  };

  /// Opções mostradas ao usuário (sem [none]).
  static const choices = [earthworks, painting, masonry, other];
}
