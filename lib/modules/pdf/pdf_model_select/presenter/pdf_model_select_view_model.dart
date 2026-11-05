import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget_executive_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget_professional_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget_simple_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfModelSelectViewModel extends ChangeNotifier {
  final PdfGenerateBudgetSimpleUsecase _pdfGenerateBudgetUsecase;
  final PdfGenerateBudgetExecutiveUsecase _pdfGenerateExecutiveUseCase;
  final PdfGenerateBudgetProfessionalUsecase _pdfGenerateProfessionalUseCase;
  final PdfRepository _pdfRepository;
  final ConvertCoinRepository _moneyConvert;

  PdfModelSelectViewModel({
    PdfGenerateBudgetSimpleUsecase? pdfGenerateBudgetUsecase,
    PdfGenerateBudgetExecutiveUsecase? pdfGenerateExecutiveUseCase,
    PdfGenerateBudgetProfessionalUsecase? pdfGenerateProfessionalUseCase,
    PdfRepository? pdfRepository,
    ConvertCoinRepository? convertCoinRepository,
  }) : _pdfGenerateBudgetUsecase =
           pdfGenerateBudgetUsecase ?? getIt<PdfGenerateBudgetSimpleUsecase>(),
       _pdfGenerateExecutiveUseCase =
           pdfGenerateExecutiveUseCase ??
           getIt<PdfGenerateBudgetExecutiveUsecase>(),
       _pdfGenerateProfessionalUseCase =
           pdfGenerateProfessionalUseCase ??
           getIt<PdfGenerateBudgetProfessionalUsecase>(),
       _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>();

  final PageController pageController = PageController();
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  OwnerPdf? _owner;

  OwnerPdf? get owner => _owner;

  bool _loading = true;

  bool get loading => _loading;

  Uint8List? _standardBytes;
  Uint8List? _executiveBytes;
  Uint8List? _professionalBytes;

  Uint8List? get standardBytes => _standardBytes;

  Uint8List? get executiveBytes => _executiveBytes;

  Uint8List? get professionalBytes => _professionalBytes;

  bool _saving = false;

  bool get saving => _saving;

  static const List<Map<String, String>> _layouts = [
    {'key': 'standard', 'label': 'Padrão'},
    {'key': 'executive', 'label': 'Executivo'},
    {'key': 'professional', 'label': 'Profissional'},
  ];

  List<Map<String, String>> get layouts => _layouts;

  Future<void> inicialData() async {
    _loading = true;
    notifyListeners();

    final ownerResult = await _pdfRepository.fetchInformationEnterprise();
    if (ownerResult is Ok<OwnerPdf>) {
      _owner = ownerResult.value;
    }

    await _generateDemos();

    _loading = false;
    notifyListeners();
  }

  Future<void> _generateDemos() async {
    final owner = _owner ?? OwnerPdf(empresa: 'Sua Empresa');
    final customer = CustomerInfo(
      id: '001',
      data: '01/01/2025',
      customerName: 'Cliente de Demonstração',
      phone: '(11) 99999-9999',
      street: 'RUA EXEMPLO, 123',
      city: 'SÃO PAULO',
      zip: '01000-000',
    );
    final items = <ItemsBudget>[
      ItemsBudget(
        DESCRICAO: 'Produto exemplo',
        MEDIDA: 'unidade',
        QTD: 2,
        PRECO: 50.0,
        TOTAL: 100.0,
        CATEGORIA: 'Produtos',
      ),
      ItemsBudget(
        DESCRICAO: 'Serviço exemplo',
        MEDIDA: 'hora',
        QTD: 1,
        PRECO: 150.0,
        TOTAL: 150.0,
        CATEGORIA: 'Serviços',
      ),
    ];
    final observations = <ObservationPdf>[
      ObservationPdf(data: '01/01/2025', observacao: 'Demonstração do layout'),
    ];

    try {
      _standardBytes = await _pdfGenerateBudgetUsecase.patternPDFBytes(
        countService: 1,
        countProduct: 1,
        totalPriceBudget: _moneyConvert.convertFromDouble(250.0),
        totalPriceProducts: _moneyConvert.convertFromDouble(100.0),
        totalPriceServices: _moneyConvert.convertFromDouble(150.0),
        items: List<ItemsBudget>.from(items),
        customer: customer,
        owner: owner,
        observations: List<ObservationPdf>.from(observations),
      );

      _executiveBytes = await _pdfGenerateExecutiveUseCase.executivePDFBytes(
        countService: 1,
        countProduct: 1,
        totalPriceBudget: _moneyConvert.convertFromDouble(250.0),
        totalPriceProducts: _moneyConvert.convertFromDouble(100.0),
        totalPriceServices: _moneyConvert.convertFromDouble(150.0),
        items: List<ItemsBudget>.from(items),
        customer: customer,
        owner: owner,
        observations: List<ObservationPdf>.from(observations),
      );

      _professionalBytes = await _pdfGenerateProfessionalUseCase
          .professionalPDFBytes(
            countService: 1,
            countProduct: 1,
            totalPriceBudget: _moneyConvert.convertFromDouble(250.0),
            totalPriceProducts: _moneyConvert.convertFromDouble(100.0),
            totalPriceServices: _moneyConvert.convertFromDouble(150.0),
            items: List<ItemsBudget>.from(items),
            customer: customer,
            owner: owner,
            observations: List<ObservationPdf>.from(observations),
          );
    } catch (_) {
      // Falha silenciosa nos demos — a View pode mostrar placeholder
    }
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<bool> selectCurrentLayout() async {
    final layoutKey = _layouts[_currentIndex]['key'];
    if (layoutKey == null) return false;

    _saving = true;
    notifyListeners();

    try {
      OwnerPdf updated;
      if (_owner != null) {
        updated = OwnerPdf(
          rua: _owner!.rua,
          empresa: _owner!.empresa,
          email: _owner!.email,
          cnpj: _owner!.cnpj,
          bairro: _owner!.bairro,
          city: _owner!.city,
          cep: _owner!.cep,
          fotoId: _owner!.fotoId,
          fone: _owner!.fone,
          logoName: _owner!.logoName,
          pdfLayoutType: layoutKey,
        );
      } else {
        updated = OwnerPdf(pdfLayoutType: layoutKey);
      }

      final result = await _pdfRepository.saveInformationEnterprise(updated);
      _saving = false;
      notifyListeners();
      return result is Ok<void>;
    } catch (_) {
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
