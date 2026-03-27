class ShopCatalogProduct {
  const ShopCatalogProduct({
    required this.code,
    required this.name,
    required this.description,
    required this.caseInfo,
    required this.unitPrice,
    required this.unitLabel,
    required this.imageAssetPath,
    required this.badgeLabel,
  });

  final String code;
  final String name;
  final String description;
  final String caseInfo;
  final double unitPrice;
  final String unitLabel;
  final String imageAssetPath;
  final String badgeLabel;

  static const List<ShopCatalogProduct> demoCatalog = <ShopCatalogProduct>[
    ShopCatalogProduct(
      code: 'NESCAFE_3IN1',
      name: 'NESCAFE 3in1',
      description: 'Original - 20g sachet',
      caseInfo: '1 case = 24 sachets',
      unitPrice: 780,
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/nescafe_3in1.png',
      badgeLabel: 'NC',
    ),
    ShopCatalogProduct(
      code: 'MILO_400G',
      name: 'MILO Powder',
      description: 'Activ-Go - 400g tin',
      caseInfo: '1 case = 12 tins',
      unitPrice: 3240,
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/milo_400g.png',
      badgeLabel: 'MI',
    ),
    ShopCatalogProduct(
      code: 'EVERYDAY_400G',
      name: 'Nestle Everyday',
      description: 'Milk powder - 400g pack',
      caseInfo: '1 case = 24 packs',
      unitPrice: 5460,
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/nestle_everyday.png',
      badgeLabel: 'ED',
    ),
    ShopCatalogProduct(
      code: 'MAGGI_CHICKEN',
      name: 'MAGGI Noodles',
      description: 'Chicken - 73g pack',
      caseInfo: '1 case = 30 packs',
      unitPrice: 1950,
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/maggi_chicken.png',
      badgeLabel: 'MG',
    ),
  ];
}
