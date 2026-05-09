import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';
import 'package:mobile/features/home/presentation/widgets/activity_card.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

class ShopOwnerOrdersTab extends StatelessWidget {
  const ShopOwnerOrdersTab({
    super.key,
    required this.isTablet,
    required this.controller,
    required this.onCartTap,
  });

  final bool isTablet;
  final ShopOwnerDashboardController controller;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Orders',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review previous orders or open the cart from the top-right icon.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                IconButton.filledTonal(
                  onPressed: onCartTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceTint,
                    foregroundColor: AppTheme.primaryBrownDark,
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (controller.cartQuantityTotal > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.proceedOrderOlive,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${controller.cartQuantityTotal}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.isLoadingOrders)
          const Center(child: CircularProgressIndicator())
        else if (controller.ordersError != null)
          _MessageCard(
            title: 'Orders unavailable',
            message: controller.ordersError!,
          )
        else if (controller.orders.isEmpty)
          const _MessageCard(
            title: 'No orders yet',
            message:
                'Your confirmed orders will appear here after you place the first one.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return _OrderHistoryCard(
                order: order,
                onTap: () => _showOrderDetails(context, order),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showOrderDetails(BuildContext context, ShopOrder order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              top: 12,
              right: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.outlineWarm,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Order details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            order.orderCode,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _friendlyStatus(order.status),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryBrownDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDate(order.placedAt)} at ${_formatTime(order.placedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceTint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _statusNoteForOrder(order),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBrownDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.34,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: order.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWarm,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.outlineWarm.withAlpha(100),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.productName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.textDark,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} x ${_formatCurrency(item.casePrice)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSoft,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatCurrency(item.lineTotal),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryBrownDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: <Widget>[
                        _OrderAmountRow(
                          label: 'Total before promotion',
                          value: _formatCurrency(order.subtotalBeforeDiscount),
                        ),
                        if (order.promotionDiscountTotal > 0) ...<Widget>[
                          const SizedBox(height: 10),
                          _OrderAmountRow(
                            label:
                                order.appliedPromotionCode?.trim().isNotEmpty ==
                                    true
                                ? 'Promotion discount (${order.appliedPromotionCode})'
                                : 'Promotion discount',
                            value:
                                '-${_formatCurrency(order.promotionDiscountTotal)}',
                            valueColor: AppTheme.proceedOrderOlive,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _OrderAmountRow(
                          label: 'Total after promotion',
                          value: _formatCurrency(order.totalAfterDiscount),
                          isEmphasized: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderAmountRow extends StatelessWidget {
  const _OrderAmountRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isEmphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isEmphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSoft,
            fontWeight: FontWeight.w600,
          );

    final valueStyle = isEmphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
            color: valueColor ?? AppTheme.primaryBrownDark,
            fontWeight: FontWeight.w800,
          )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor ?? AppTheme.primaryBrownDark,
            fontWeight: FontWeight.w700,
          );

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class ShopOwnerActivityTab extends StatelessWidget {
  const ShopOwnerActivityTab({
    super.key,
    required this.isTablet,
    required this.controller,
  });

  final bool isTablet;
  final ShopOwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Activity',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Important alerts such as account updates, sign-ins, sign-outs, and order confirmations are shown here.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
        ),
        const SizedBox(height: 20),
        if (controller.isLoadingActivities)
          const Center(child: CircularProgressIndicator())
        else if (controller.activitiesError != null)
          _MessageCard(
            title: 'Activity unavailable',
            message: controller.activitiesError!,
          )
        else if (controller.activities.isEmpty)
          const _MessageCard(
            title: 'No activity yet',
            message:
                'Your alerts will appear here once account activity starts.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final activity = controller.activities[index];
              return ActivityCard(activity: activity);
            },
          ),
      ],
    );
  }
}

class ShopOwnerSettingsTab extends StatelessWidget {
  const ShopOwnerSettingsTab({
    super.key,
    required this.isTablet,
    required this.profile,
    required this.onSecurityTap,
    required this.onInsightsTap,
  });

  final bool isTablet;
  final ShopOwnerProfile profile;
  final VoidCallback onSecurityTap;
  final VoidCallback onInsightsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage security for your account under the same shop-owner theme.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
        ),
        const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(isTablet ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primaryBrownDark.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                title: Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'View your shop\'s sales performance chart and top trending products.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onInsightsTap,
              ),
              Divider(color: AppTheme.outlineWarm.withAlpha(110)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: AppTheme.securitySlate,
                  ),
                ),
                title: Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Change your password by entering the current password and the new password twice.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSecurityTap,
              ),
              Divider(color: AppTheme.outlineWarm.withAlpha(110)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${profile.displayShopName}\n${profile.email}\n${profile.phoneNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order, required this.onTap});

  final ShopOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.primaryBrownDark.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.orderCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _friendlyStatus(order.status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBrownDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _formatDate(order.placedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                ),
                Text(
                  _formatCurrency(order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBrownDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final normalized = value.toStringAsFixed(2);
  final parts = normalized.split('.');
  final whole = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return 'LKR ${buffer.toString()}.$decimal';
}

String _friendlyStatus(String status) {
  final normalized = status.trim();
  if (normalized.isEmpty) {
    return 'Placed';
  }

  return normalized
      .toLowerCase()
      .split(RegExp(r'[_\s]+'))
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _statusNoteForOrder(ShopOrder order) {
  final normalizedStatus = order.status.trim().toUpperCase();
  final customerNote = order.customerNote?.trim();

  if (customerNote != null &&
      customerNote.isNotEmpty &&
      <String>{
        'PROCEED',
        'APPROVED',
        'ASSIGNED',
        'DELAYED',
        'CANCELLED',
        'COMPLETE',
        'COMPLETED',
      }.contains(normalizedStatus)) {
    return customerNote;
  }

  switch (normalizedStatus) {
    case 'PROCEED':
    case 'APPROVED':
      return order.deliveryDueAt != null
          ? 'Your order is approved and is now proceeding for delivery before ${_formatDate(order.deliveryDueAt!)}.'
          : 'Your order is approved and is now proceeding for delivery.';
    case 'ASSIGNED':
      return 'Your order has been assigned to a distributor and is being prepared for delivery.';
    case 'DELAYED':
      return order.delayReason != null && order.delayReason!.trim().isNotEmpty
          ? 'Delivery delayed: ${order.delayReason!}'
          : 'Your order has been delayed. Please check again later for the latest delivery update.';
    case 'CANCELLED':
      return 'Your order could not be processed. Please review the latest activity update for the reason.';
    case 'PROCESS':
    case 'PROCESSING':
    case 'PROCESSED':
      return 'Order will be delivered within 1-2 business days.';
    case 'DELIVERY':
    case 'DELIVERING':
    case 'ON_THE_WAY':
      return 'Your order is on the way.';
    case 'COMPLETE':
    case 'COMPLETED':
      return 'Order completed on ${_formatDate(order.placedAt)}.';
    case 'PLACED':
    default:
      return order.isOverdue
          ? 'Your order has passed the normal delivery window and is waiting for an update.'
          : 'Your order will be processed soon.';
  }
}

String _formatDate(DateTime dateTime) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = '${dateTime.minute}'.padLeft(2, '0');
  final meridiem = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $meridiem';
}
