import 'package:oflite/modules/legal/domain/entity/legal_document.dart';

/// Textos legais em português (`/termos-de-uso`, `/politica-de-privacidade`).
class LegalPtString {
  LegalPtString._();

  static const String _email = 'davidelias1511@gmail.com';
  static const String _privacyUrl =
      'https://orcamentofacil-lite.web.app/politica-de-privacidade';

  static const LegalDocument terms = LegalDocument(
    title: 'Termos de Uso (EULA) – Orçamentos e Recibos - PDF',
    lastUpdated: 'Última atualização: 17/11/2026',
    switchLanguageLabel: 'English',
    switchLanguagePath: '/terms-of-use',
    otherDocumentLabel: 'Política de Privacidade',
    otherDocumentPath: '/politica-de-privacidade',
    footer: 'Contato: $_email',
    sections: [
      LegalSection(
        '1. Partes',
        'Este contrato é celebrado entre você ("Usuário") e David Elias da '
            'Conceição, desenvolvedor independente, que publica aplicativos sob '
            'o nome House Studio Apps ("Desenvolvedor"). Este contrato é apenas '
            'entre você e o Desenvolvedor, e não com a Apple Inc. ("Apple"). O '
            'Desenvolvedor, e não a Apple, é o único responsável pelo app e seu '
            'conteúdo.',
      ),
      LegalSection(
        '2. Licença',
        'É concedida ao Usuário uma licença limitada, não exclusiva, '
            'intransferível e revogável para usar o app em dispositivos Apple '
            'que possua ou controle, conforme as Regras de Uso dos Termos de '
            'Serviço da App Store.',
      ),
      LegalSection(
        '3. Assinaturas',
        '• O app oferece assinaturas auto-renováveis: Plano Mensal – R\$ 4,90/mês.\n'
            '• O pagamento é cobrado na conta Apple ao confirmar a compra.\n'
            '• A assinatura renova automaticamente, a menos que seja cancelada '
            'com pelo menos 24 horas de antecedência do fim do período vigente.\n'
            '• A renovação é cobrada nas 24 horas anteriores ao fim do período.\n'
            '• O Usuário pode gerenciar e cancelar nos Ajustes da conta Apple.\n'
            '• Período de teste gratuito não utilizado é perdido ao assinar.',
      ),
      LegalSection(
        '4. Conteúdo do Usuário e Dados',
        'O Usuário é responsável pelos dados inseridos (clientes, orçamentos, '
            'recibos). O tratamento de dados pessoais segue nossa Política de '
            'Privacidade: $_privacyUrl, em conformidade com a LGPD.',
      ),
      LegalSection(
        '5. Uso Proibido',
        'É vedado usar o app para fins ilícitos, fazer engenharia reversa, ou '
            'violar direitos de terceiros.',
      ),
      LegalSection(
        '6. Manutenção e Suporte',
        'O Desenvolvedor é o único responsável por manutenção e suporte. A '
            'Apple não tem qualquer obrigação de fornecer suporte. Contato: '
            '$_email.',
      ),
      LegalSection(
        '7. Garantia',
        'O app é fornecido "no estado em que se encontra". Em caso de falha de '
            'qualquer garantia aplicável, o Usuário pode notificar a Apple, que '
            'reembolsará o preço de compra, se houver. Na extensão máxima '
            'permitida por lei, a Apple não terá nenhuma outra obrigação de '
            'garantia.',
      ),
      LegalSection(
        '8. Reclamações',
        'O Desenvolvedor, e não a Apple, é responsável por quaisquer '
            'reclamações relacionadas ao app, incluindo responsabilidade pelo '
            'produto, descumprimento legal ou regulatório e de proteção ao '
            'consumidor.',
      ),
      LegalSection(
        '9. Propriedade Intelectual',
        'Em caso de alegação de violação de propriedade intelectual por '
            'terceiros, o Desenvolvedor, e não a Apple, será responsável pela '
            'investigação, defesa e resolução.',
      ),
      LegalSection(
        '10. Conformidade Legal',
        'O Usuário declara não estar em país sujeito a embargo dos EUA nem em '
            'lista de partes restritas do governo dos EUA.',
      ),
      LegalSection(
        '11. Terceiro Beneficiário',
        'A Apple e suas subsidiárias são terceiras beneficiárias deste contrato '
            'e, após o aceite, terá o direito de executá-lo contra o Usuário.',
      ),
      LegalSection(
        '12. Alterações e Foro',
        'Estes termos podem ser atualizados; o uso continuado implica aceite. '
            'Fica eleito o foro de Sorocaba/SP.',
      ),
    ],
  );

  static const LegalDocument privacy = LegalDocument(
    title: 'Política de Privacidade – Orçamento Fácil',
    lastUpdated: 'Última atualização: 17/11/2026',
    switchLanguageLabel: 'English',
    switchLanguagePath: '/privacy-policy',
    otherDocumentLabel: 'Termos de Uso',
    otherDocumentPath: '/termos-de-uso',
    footer:
        'Esta política de privacidade foi criada por David, CEO e proprietário '
        'da House Studio Apps.',
    intro:
        'Esta política de privacidade descreve como o Orçamento Fácil, um '
        'aplicativo comercial desenvolvido pela House Studio Apps, coleta, '
        'utiliza e protege as informações pessoais dos usuários, incluindo '
        'imagens. Ao utilizar nosso serviço, você concorda com os termos desta '
        'política.',
    sections: [
      LegalSection(
        'Coleta e Uso de Informações',
        'Para proporcionar uma experiência melhor, o Orçamento Fácil pode '
            'solicitar informações de identificação pessoal, como nome de '
            'usuário, endereço, local e fotos. As imagens fornecidas pelo '
            'usuário são salvas no Firebase e não são coletadas por nós para '
            'qualquer finalidade, a menos que você escolha compartilhá-las '
            'dentro do aplicativo, e seu uso é estritamente para as funções do '
            'app.',
      ),
      LegalSection(
        'Compartilhamento de Imagens no Aplicativo',
        'Se você optar por compartilhar imagens dentro do aplicativo Orçamento '
            'Fácil, essas imagens podem ser visíveis para outros usuários, '
            'dependendo das configurações de compartilhamento que você escolher.',
      ),
      LegalSection(
        'Imagens em Serviços de Terceiros',
        'O Orçamento Fácil faz uso de serviços de terceiros, como o Firebase, '
            'que coletam informações, incluindo imagens, exclusivamente com o '
            'propósito de aprimorar os serviços oferecidos pelo aplicativo. Em '
            'nenhum momento coletamos dados para qualquer finalidade que não '
            'seja a utilização direta dentro do aplicativo.\n\n'
            'Reforçamos que as imagens coletadas são estritamente destinadas ao '
            'uso interno do aplicativo e não são compartilhadas ou analisadas '
            'para outros fins. Para obter informações detalhadas sobre como '
            'esses provedores de serviços de terceiros tratam suas imagens, '
            'recomendamos consultar suas respectivas políticas de privacidade. '
            'Sua privacidade e segurança são fundamentais para nós.',
      ),
      LegalSection(
        'Segurança das Imagens',
        'Valorizamos a segurança das imagens fornecidas pelos usuários. '
            'Adotamos medidas comercialmente aceitáveis para protegê-las. No '
            'entanto, observe que nenhum método de transmissão pela Internet ou '
            'armazenamento eletrônico é 100% seguro e confiável, e não podemos '
            'garantir a segurança absoluta das imagens.',
      ),
      LegalSection(
        'Privacidade das Crianças',
        'O Orçamento Fácil não coleta intencionalmente informações de '
            'identificação pessoal, incluindo imagens, de crianças menores de '
            '13 anos. Se você acredita que seu filho forneceu informações '
            'pessoais, incluindo imagens, entre em contato conosco para que '
            'possamos tomar as medidas necessárias.',
      ),
      LegalSection(
        'Alterações a esta Política de Privacidade',
        'Podemos atualizar esta política periodicamente. Recomendamos que você '
            'a revise regularmente para verificar se há alterações. '
            'Notificaremos sobre quaisquer alterações publicando a nova política '
            'nesta página.',
      ),
      LegalSection(
        'Contate-Nos',
        'Se você tiver alguma dúvida ou sugestão sobre nossa Política de '
            'Privacidade, incluindo o tratamento de imagens, entre em contato '
            'conosco em $_email.',
      ),
    ],
  );
}
