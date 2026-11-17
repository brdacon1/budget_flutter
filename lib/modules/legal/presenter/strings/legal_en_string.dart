import 'package:oflite/modules/legal/domain/entity/legal_document.dart';

/// Legal texts in English (`/terms-of-use`, `/privacy-policy`).
class LegalEnString {
  LegalEnString._();

  static const String _email = 'davidelias1511@gmail.com';
  static const String _privacyUrl =
      'https://orcamentofacil-lite.web.app/privacy-policy';

  static const LegalDocument terms = LegalDocument(
    title: 'Terms of Use (EULA) – Orçamentos e Recibos - PDF',
    lastUpdated: 'Last updated: November 17, 2026',
    switchLanguageLabel: 'Português',
    switchLanguagePath: '/termos-de-uso',
    otherDocumentLabel: 'Privacy Policy',
    otherDocumentPath: '/privacy-policy',
    footer: 'Contact: $_email',
    sections: [
      LegalSection(
        '1. Parties',
        'This agreement is entered into between you ("User") and David Elias da '
            'Conceição, an independent developer publishing apps under the name '
            'House Studio Apps ("Developer"). This agreement is concluded solely '
            'between you and the Developer, and not with Apple Inc. ("Apple"). '
            'The Developer, not Apple, is solely responsible for the app and its '
            'content.',
      ),
      LegalSection(
        '2. License',
        'The User is granted a limited, non-exclusive, non-transferable, '
            'revocable license to use the app on Apple-branded devices that the '
            'User owns or controls, as permitted by the Usage Rules set forth in '
            'the App Store Terms of Service.',
      ),
      LegalSection(
        '3. Subscriptions',
        '• The app offers auto-renewable subscriptions: Monthly Plan – price as '
            'shown in the App Store at the time of purchase.\n'
            '• Payment is charged to the User\'s Apple Account upon confirmation '
            'of purchase.\n'
            '• The subscription renews automatically unless canceled at least 24 '
            'hours before the end of the current period.\n'
            '• Renewal is charged within 24 hours prior to the end of the current '
            'period.\n'
            '• The User can manage and cancel subscriptions in their Apple Account '
            'settings.\n'
            '• Any unused portion of a free trial period is forfeited when the '
            'User purchases a subscription.',
      ),
      LegalSection(
        '4. User Content and Data',
        'The User is responsible for the data entered (clients, quotes, '
            'receipts). Personal data is processed in accordance with our Privacy '
            'Policy: $_privacyUrl, in compliance with applicable data protection '
            'laws, including Brazil\'s LGPD.',
      ),
      LegalSection(
        '5. Prohibited Use',
        'The User may not use the app for unlawful purposes, reverse engineer '
            'it, or infringe the rights of third parties.',
      ),
      LegalSection(
        '6. Maintenance and Support',
        'The Developer is solely responsible for providing maintenance and '
            'support for the app. Apple has no obligation whatsoever to furnish '
            'any maintenance or support services. Contact: $_email.',
      ),
      LegalSection(
        '7. Warranty',
        'The app is provided "as is". In the event of any failure of the app to '
            'conform to any applicable warranty, the User may notify Apple, and '
            'Apple will refund the purchase price, if any. To the maximum extent '
            'permitted by law, Apple will have no other warranty obligation '
            'whatsoever.',
      ),
      LegalSection(
        '8. Product Claims',
        'The Developer, not Apple, is responsible for addressing any claims '
            'relating to the app, including product liability claims, failure to '
            'conform to legal or regulatory requirements, and consumer protection '
            'claims.',
      ),
      LegalSection(
        '9. Intellectual Property',
        'In the event of any third-party claim that the app infringes '
            'intellectual property rights, the Developer, not Apple, will be '
            'solely responsible for its investigation, defense, settlement, and '
            'discharge.',
      ),
      LegalSection(
        '10. Legal Compliance',
        'The User represents that they are not located in a country subject to '
            'a U.S. Government embargo and are not listed on any U.S. Government '
            'list of prohibited or restricted parties.',
      ),
      LegalSection(
        '11. Third-Party Beneficiary',
        'Apple and its subsidiaries are third-party beneficiaries of this '
            'agreement, and upon the User\'s acceptance, Apple will have the '
            'right to enforce this agreement against the User as a third-party '
            'beneficiary.',
      ),
      LegalSection(
        '12. Changes and Jurisdiction',
        'These terms may be updated from time to time; continued use of the app '
            'constitutes acceptance. These terms are governed by the laws of '
            'Brazil, and the courts of Sorocaba/SP shall have jurisdiction.',
      ),
    ],
  );

  static const LegalDocument privacy = LegalDocument(
    title: 'Privacy Policy – Orçamento Fácil',
    lastUpdated: 'Last updated: November 17, 2026',
    switchLanguageLabel: 'Português',
    switchLanguagePath: '/politica-de-privacidade',
    otherDocumentLabel: 'Terms of Use',
    otherDocumentPath: '/terms-of-use',
    footer:
        'This privacy policy was created by David, CEO and owner of House '
        'Studio Apps.',
    intro:
        'This privacy policy describes how Orçamento Fácil, a commercial app '
        'developed by House Studio Apps, collects, uses and protects users\' '
        'personal information, including images. By using our service, you '
        'agree to the terms of this policy.',
    sections: [
      LegalSection(
        'Information Collection and Use',
        'To provide a better experience, Orçamento Fácil may request personally '
            'identifiable information, such as username, address, location and '
            'photos. Images provided by the user are stored in Firebase and are '
            'not collected by us for any purpose unless you choose to share them '
            'within the app, and they are used strictly for the app\'s features.',
      ),
      LegalSection(
        'Sharing Images in the App',
        'If you choose to share images within the Orçamento Fácil app, those '
            'images may be visible to other users, depending on the sharing '
            'settings you choose.',
      ),
      LegalSection(
        'Images in Third-Party Services',
        'Orçamento Fácil uses third-party services, such as Firebase, which '
            'collect information, including images, solely for the purpose of '
            'improving the services offered by the app. At no time do we collect '
            'data for any purpose other than direct use within the app.\n\n'
            'We emphasize that collected images are intended strictly for '
            'internal use by the app and are not shared or analyzed for other '
            'purposes. For detailed information on how these third-party service '
            'providers handle your images, we recommend reviewing their '
            'respective privacy policies. Your privacy and security are '
            'fundamental to us.',
      ),
      LegalSection(
        'Image Security',
        'We value the security of the images provided by users and adopt '
            'commercially acceptable measures to protect them. However, please '
            'note that no method of transmission over the Internet or electronic '
            'storage is 100% secure and reliable, and we cannot guarantee the '
            'absolute security of images.',
      ),
      LegalSection(
        'Children\'s Privacy',
        'Orçamento Fácil does not knowingly collect personally identifiable '
            'information, including images, from children under 13. If you '
            'believe your child has provided personal information, including '
            'images, please contact us so that we can take the necessary '
            'actions.',
      ),
      LegalSection(
        'Changes to This Privacy Policy',
        'We may update this policy from time to time. We recommend that you '
            'review it periodically for any changes. We will notify you of any '
            'changes by posting the new policy on this page.',
      ),
      LegalSection(
        'Contact Us',
        'If you have any questions or suggestions about our Privacy Policy, '
            'including the handling of images, please contact us at $_email.',
      ),
    ],
  );
}
