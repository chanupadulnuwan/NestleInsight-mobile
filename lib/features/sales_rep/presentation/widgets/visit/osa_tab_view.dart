import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_visit_cubit.dart';
import 'osa_product_card.dart';
import 'osa_footer.dart';

class OSATabView extends StatelessWidget {
  const OSATabView({
    super.key,
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final issuesCount = state.osaStatuses.values
        .where((v) => v.$1 == OSAStatus.outOfStock)
        .length;
    
    // Logic for "Bringing to Shelf" could be based on a flag in OOS reason
    final bringingToShelfCount = state.osaStatuses.values
        .where((v) => v.$1 == OSAStatus.outOfStock && v.$2 == 'Backroom only')
        .length;

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppTheme.outlineWarm, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'On Shelf Availability',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineWarm),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.products.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF5F0EB),
                    ),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final statusInfo = state.osaStatuses[product.id] ?? (OSAStatus.none, null);
                      
                      return OSAProductCard(
                        product: product,
                        status: statusInfo.$1,
                        reason: statusInfo.$2,
                        onStatusChanged: (status, reason) {
                          cubit.updateOSAStatus(product.id, status, reason);
                        },
                      );
                    },
                  ),
                ),
                InkWell(
                  onTap: () => cubit.markAllInStock(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.outlineWarm)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Mark All in Stock',
                        style: TextStyle(
                          color: AppTheme.textSoft,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        OSAFooter(
          issuesCount: issuesCount,
          bringingToShelfCount: bringingToShelfCount,
          onNext: onNext,
        ),
      ],
    );
  }
}
