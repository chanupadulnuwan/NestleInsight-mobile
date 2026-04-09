/// Request body sent to POST /activities/order-feedback
class OrderFeedbackRequest {
  const OrderFeedbackRequest({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  final String orderId;

  /// Star rating between 1 and 5 (inclusive).
  final int rating;

  /// Optional written comment from the shop owner.
  final String? comment;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'orderId': orderId,
    'rating': rating,
    if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
  };
}
