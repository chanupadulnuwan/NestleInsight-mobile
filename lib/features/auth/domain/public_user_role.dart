enum PublicUserRole { shopOwner, territoryDistributor, salesRepresentative }

extension PublicUserRoleExtension on PublicUserRole {
  String get label {
    switch (this) {
      case PublicUserRole.shopOwner:
        return 'Shop Owner';
      case PublicUserRole.territoryDistributor:
        return 'Territory Distributor';
      case PublicUserRole.salesRepresentative:
        return 'Sales Representative';
    }
  }

  String get backendValue {
    switch (this) {
      case PublicUserRole.shopOwner:
        return 'SHOP_OWNER';
      case PublicUserRole.territoryDistributor:
        return 'TERRITORY_DISTRIBUTOR';
      case PublicUserRole.salesRepresentative:
        return 'SALES_REP';
    }
  }

  bool get isEmployeeRole {
    switch (this) {
      case PublicUserRole.shopOwner:
        return false;
      case PublicUserRole.territoryDistributor:
      case PublicUserRole.salesRepresentative:
        return true;
    }
  }
}
