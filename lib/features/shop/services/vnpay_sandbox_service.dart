import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class VnPayTransactionResult {
  const VnPayTransactionResult({
    required this.responseCode,
    required this.txnRef,
    required this.transactionNo,
    required this.bankCode,
    required this.amountVnd,
    required this.payDate,
    required this.orderInfo,
    required this.secureHash,
    required this.signedPaymentUrl,
    this.message = '',
  });

  final String responseCode;
  final String txnRef;
  final String transactionNo;
  final String bankCode;
  final int amountVnd;
  final String payDate;
  final String orderInfo;
  final String secureHash;
  final String signedPaymentUrl;
  final String message;

  bool get isSuccess => responseCode == '00';

  String get statusDescription =>
      message.isNotEmpty ? message : VnPaySandboxService.describeResponseCode(responseCode);
}

/// Official VNPay v2.1.0 Sandbox payment signing, URL builder, and return validator.
/// Reference: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
class VnPaySandboxService {
  VnPaySandboxService._();

  static const String sandboxEndpoint =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String defaultReturnUrl =
      'https://fashion-business-app.web.app/vnpay-return';
  static const String version = '2.1.0';

  // Configurable via --dart-define=VNPAY_TMN_CODE=... & VNPAY_HASH_SECRET=...
  // Falls back to Sandbox test configuration when not supplied.
  static const String tmnCode = String.fromEnvironment(
    'VNPAY_TMN_CODE',
    defaultValue: 'VELORATEST',
  );
  static const String hashSecret = String.fromEnvironment(
    'VNPAY_HASH_SECRET',
    defaultValue: 'VELORAVNPAYSANDBOXSECRETKEY2026HMACSHA512',
  );

  // Official VNPay Sandbox test card (NCB Bank)
  static const String testBankCode = 'NCB';
  static const String testCardNumber = '9704198526191432198';
  static const String testCardHolder = 'NGUYEN VAN A';
  static const String testCardIssueDate = '07/15';
  static const String testOtpCode = '123456';

  static String formatVnpDate(DateTime dt) =>
      DateFormat('yyyyMMddHHmmss').format(dt);

  static String sanitizeOrderInfo(String raw) {
    var s = raw.trim();
    const map = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'đ': 'd', 'Đ': 'D',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-_]'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Generates HMAC-SHA512 hex digest using the VNPay secret key.
  static String hmacSha512(String secretKey, String data) {
    final hmac = Hmac(sha512, utf8.encode(secretKey));
    return hmac.convert(utf8.encode(data)).toString();
  }

  /// Builds the sorted VNPay v2.1.0 request payload & signed sandbox URL.
  static ({
    String paymentUrl,
    String secureHash,
    Map<String, String> params,
  }) buildSignedPaymentRequest({
    required String txnRef,
    required int amountVnd,
    required String orderInfo,
    String bankCode = '',
    String locale = 'vn',
    String ipAddr = '127.0.0.1',
    String returnUrl = defaultReturnUrl,
    String customTmnCode = tmnCode,
    String customHashSecret = hashSecret,
    DateTime? now,
  }) {
    final created = now ?? DateTime.now();
    final expire = created.add(const Duration(minutes: 15));
    final cleanInfo = sanitizeOrderInfo(orderInfo);

    final params = <String, String>{
      'vnp_Version': version,
      'vnp_Command': 'pay',
      'vnp_TmnCode': customTmnCode,
      'vnp_Amount': (amountVnd * 100).toString(),
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': txnRef,
      'vnp_OrderInfo':
          cleanInfo.isNotEmpty ? cleanInfo : 'Thanh toan don hang VELORA',
      'vnp_OrderType': 'fashion',
      'vnp_Locale': locale == 'en' ? 'en' : 'vn',
      'vnp_ReturnUrl': returnUrl,
      'vnp_IpAddr': ipAddr,
      'vnp_CreateDate': formatVnpDate(created),
      'vnp_ExpireDate': formatVnpDate(expire),
      if (bankCode.trim().isNotEmpty) 'vnp_BankCode': bankCode.trim(),
    };

    final sortedKeys = params.keys.toList()..sort();
    final encodedPairs = <String>[];
    for (final key in sortedKeys) {
      final value = params[key] ?? '';
      if (value.isNotEmpty) {
        encodedPairs.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    }

    final queryString = encodedPairs.join('&');
    final secureHash = hmacSha512(customHashSecret, queryString);
    final paymentUrl =
        '$sandboxEndpoint?$queryString&vnp_SecureHash=$secureHash';

    return (
      paymentUrl: paymentUrl,
      secureHash: secureHash,
      params: params,
    );
  }

  /// Verifies the HMAC-SHA512 signature returned from VNPay callback query parameters.
  static bool verifyReturnParams(
    Map<String, String> queryParams, {
    String customHashSecret = hashSecret,
  }) {
    final receivedHash = queryParams['vnp_SecureHash'] ?? '';
    if (receivedHash.isEmpty) return false;
    final filtered = Map<String, String>.from(queryParams)
      ..remove('vnp_SecureHash')
      ..remove('vnp_SecureHashType');
    final sortedKeys = filtered.keys.toList()..sort();
    final hashData = [
      for (final key in sortedKeys)
        if ((filtered[key] ?? '').isNotEmpty)
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(filtered[key]!)}',
    ].join('&');
    final expected = hmacSha512(customHashSecret, hashData);
    return expected.toLowerCase() == receivedHash.toLowerCase();
  }

  static String describeResponseCode(String code) {
    switch (code) {
      case '00':
        return 'Giao dịch thanh toán VNPay thành công.';
      case '07':
        return 'Trừ tiền thành công nhưng giao dịch bị nghi ngờ.';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking.';
      case '10':
        return 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần.';
      case '11':
        return 'Đã hết hạn chờ thanh toán (15 phút). Vui lòng thử lại.';
      case '12':
        return 'Thẻ/Tài khoản của khách hàng bị khóa.';
      case '13':
        return 'Mã xác thực OTP không chính xác.';
      case '24':
        return 'Khách hàng đã hủy giao dịch thanh toán VNPay.';
      case '51':
        return 'Tài khoản không đủ số dư để thực hiện giao dịch.';
      case '65':
        return 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày.';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì.';
      case '79':
        return 'Nhập sai mật khẩu thanh toán quá số lần quy định.';
      default:
        return 'Giao dịch VNPay không thành công (Mã lỗi: $code).';
    }
  }
}
