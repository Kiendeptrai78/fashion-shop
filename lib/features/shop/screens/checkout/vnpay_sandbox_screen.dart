import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/shop/services/vnpay_sandbox_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VnPaySandboxScreen extends StatefulWidget {
  const VnPaySandboxScreen({
    super.key,
    required this.orderId,
    required this.amountVnd,
    required this.orderInfo,
  });

  final String orderId;
  final int amountVnd;
  final String orderInfo;

  @override
  State<VnPaySandboxScreen> createState() => _VnPaySandboxScreenState();
}

class _VnPaySandboxScreenState extends State<VnPaySandboxScreen> {
  static const _vnpBlue = Color(0xFF005BAA);
  static const _vnpDarkBlue = Color(0xFF003E78);
  static const _vnpRed = Color(0xFFED1C24);

  // 0: Select Channel, 1: Enter Card Info, 2: Enter OTP
  int _step = 0;
  // 'ATM' | 'VNPAYQR' | 'INTCARD'
  String _channel = 'ATM';
  String _selectedBank = VnPaySandboxService.testBankCode;

  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _issueDate = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _processing = false;
  bool _showTechDetails = false;
  String? _otpError;
  int _remainingSeconds = 15 * 60;
  Timer? _countdownTimer;

  late final String _txnRef;
  late ({
    String paymentUrl,
    String secureHash,
    Map<String, String> params,
  }) _signedRequest;

  static const _banks = <({String code, String name, bool isTestDefault})>[
    (code: 'NCB', name: 'Ngân hàng NCB', isTestDefault: true),
    (code: 'VCB', name: 'Vietcombank', isTestDefault: false),
    (code: 'BIDV', name: 'BIDV', isTestDefault: false),
    (code: 'TCB', name: 'Techcombank', isTestDefault: false),
    (code: 'VTB', name: 'VietinBank', isTestDefault: false),
    (code: 'MB', name: 'MB Bank', isTestDefault: false),
    (code: 'ACB', name: 'ACB', isTestDefault: false),
    (code: 'VPB', name: 'VPBank', isTestDefault: false),
  ];

  @override
  void initState() {
    super.initState();
    final compactId = widget.orderId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = compactId.length >= 8
        ? compactId.substring(0, 8).toUpperCase()
        : '${DateTime.now().millisecondsSinceEpoch}';
    _txnRef = 'VELORA$suffix';
    _rebuildSignedRequest();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _finishWithCode('11', bankCode: _effectiveBankCode);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cardNumber.dispose();
    _cardHolder.dispose();
    _issueDate.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _effectiveBankCode {
    if (_channel == 'VNPAYQR') return 'VNPAYQR';
    if (_channel == 'INTCARD') return 'VISA';
    return _selectedBank;
  }

  void _rebuildSignedRequest() {
    _signedRequest = VnPaySandboxService.buildSignedPaymentRequest(
      txnRef: _txnRef,
      amountVnd: widget.amountVnd,
      orderInfo: widget.orderInfo,
      bankCode: _effectiveBankCode,
    );
  }

  String get _formattedTimer {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatVnd(int amount) =>
      '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';

  void _fillTestCard() {
    setState(() {
      if (_channel == 'INTCARD') {
        _cardNumber.text = '4000000000000002';
        _cardHolder.text = VnPaySandboxService.testCardHolder;
        _issueDate.text = '12/28';
      } else {
        _selectedBank = VnPaySandboxService.testBankCode;
        _cardNumber.text = VnPaySandboxService.testCardNumber;
        _cardHolder.text = VnPaySandboxService.testCardHolder;
        _issueDate.text = VnPaySandboxService.testCardIssueDate;
      }
      _rebuildSignedRequest();
    });
  }

  Future<void> _finishWithCode(
    String responseCode, {
    required String bankCode,
  }) async {
    if (_processing) return;
    setState(() => _processing = true);
    _rebuildSignedRequest();

    // Brief realistic gateway verification delay
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final now = DateTime.now();
    final payDate = VnPaySandboxService.formatVnpDate(now);
    final txNo = responseCode == '00'
        ? '${14000000 + math.Random().nextInt(8999999)}'
        : '';

    final result = VnPayTransactionResult(
      responseCode: responseCode,
      txnRef: _txnRef,
      transactionNo: txNo,
      bankCode: bankCode,
      amountVnd: widget.amountVnd,
      payDate: payDate,
      orderInfo: widget.orderInfo,
      secureHash: _signedRequest.secureHash,
      signedPaymentUrl: _signedRequest.paymentUrl,
      message: VnPaySandboxService.describeResponseCode(responseCode),
    );
    Navigator.of(context).pop(result);
  }

  void _handleOtpSubmit() {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _otpError = 'Vui lòng nhập mã OTP gồm 6 chữ số (Test: 123456).');
      return;
    }
    if (otp != VnPaySandboxService.testOtpCode) {
      setState(() {
        _otpError =
            'Mã OTP không đúng (Mã lỗi 13). Trên môi trường Sandbox, vui lòng nhập OTP: 123456.';
      });
      return;
    }
    setState(() => _otpError = null);
    _finishWithCode('00', bankCode: _effectiveBankCode);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0D1913) : ShopGlass.pageBackground;
    final cardBg = dark ? const Color(0xFF162233) : Colors.white;
    final border = dark ? Colors.white12 : const Color(0xFFDCE5F0);

    return PopScope(
      canPop: !_processing,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
      extendBodyBehindAppBar: true,
          backgroundColor: bg,
          appBar: TAppbar(
            leading: ShopGlassBackButton(
              tooltip: 'Hủy thanh toán',
              onPressed: _processing
                  ? null
                  : () => _finishWithCode('24', bankCode: _effectiveBankCode),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: ShopGlassDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VN',
                        style: TextStyle(
                          color: _vnpRed,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'PAY',
                        style: TextStyle(
                          color: _vnpBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cổng thanh toán VNPAY',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _vnpDarkBlue,
                        ),
                      ),
                      Text(
                        'Môi trường kiểm thử Sandbox v2.1.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5C6C64),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: ShopGlassDecoration(
                  color: _vnpDarkBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 13,
                      color: Color(0xFFFDE68A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formattedTimer,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _vnpDarkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: shopAppbarContentPadding(context, EdgeInsets.fromLTRB(16, 16, 16, 36)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Order Summary Header Card (VNPay official blue banner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_vnpDarkBlue, _vnpBlue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _vnpBlue.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: ShopGlassDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'SANDBOX TEST MODE',
                                  style: TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Mã GD: $_txnRef',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Số tiền thanh toán',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatVnd(widget.amountVnd),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: ShopGlassDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              'Đơn vị: VELORA Official Store • ${widget.orderInfo}',
                              softWrap: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Stepper Indicator
                    _StepIndicatorBar(currentStep: _step, dark: dark),
                    const SizedBox(height: 16),

                    // 3. Dynamic Step Content
                    if (_step == 0)
                      _buildSelectMethodStep(cardBg, border, dark)
                    else if (_step == 1)
                      _buildCardInputStep(cardBg, border, dark)
                    else
                      _buildOtpStep(cardBg, border, dark),

                    const SizedBox(height: 16),

                    // 4. Collapsible Technical VNPay v2.1.0 Payload Inspector
                    Container(
                      decoration: ShopGlassDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _showTechDetails = !_showTechDetails,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.shield_tick,
                                    size: 18,
                                    color: _vnpBlue,
                                  ),
                                  const SizedBox(width: 9),
                                  const Expanded(
                                    child: Text(
                                      'Tham số chữ ký số VNPay v2.1.0 (HMAC-SHA512)',
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showTechDetails
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showTechDetails) ...[
                            Divider(height: 1, color: border),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _techRow('Endpoint', VnPaySandboxService.sandboxEndpoint),
                                  _techRow('vnp_TmnCode', _signedRequest.params['vnp_TmnCode'] ?? ''),
                                  _techRow('vnp_TxnRef', _signedRequest.params['vnp_TxnRef'] ?? ''),
                                  _techRow('vnp_Amount', '${_signedRequest.params['vnp_Amount']} (×100)'),
                                  _techRow('vnp_BankCode', _effectiveBankCode),
                                  _techRow('vnp_CreateDate', _signedRequest.params['vnp_CreateDate'] ?? ''),
                                  _techRow(
                                    'vnp_SecureHash',
                                    '${_signedRequest.secureHash.substring(0, 32)}...',
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: _signedRequest.paymentUrl,
                                            ),
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Đã sao chép URL thanh toán VNPay Sandbox có chữ ký HMAC-SHA512!',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Iconsax.copy, size: 15),
                                        label: const Text(
                                          'Sao chép URL ký số',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.parse(
                                            _signedRequest.paymentUrl,
                                          );
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        icon: const Icon(
                                          Iconsax.export_1,
                                          size: 15,
                                        ),
                                        label: const Text(
                                          'Mở sandbox.vnpayment.vn',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Cancel / Simulate failure link
                    Center(
                      child: TextButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _finishWithCode(
                                  '24',
                                  bankCode: _effectiveBankCode,
                                ),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 17,
                          color: _vnpRed,
                        ),
                        label: const Text(
                          'Hủy giao dịch thanh toán (Mã 24)',
                          style: TextStyle(
                            color: _vnpRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_processing)
                Container(
                  color: Colors.black.withValues(alpha: 0.48),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 22,
                    ),
                    decoration: ShopGlassDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _vnpBlue),
                        SizedBox(height: 14),
                        Text(
                          'Đang xác thực giao dịch với VNPay...',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSelectMethodStep(Color cardBg, Color border, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShopGlassDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn phương thức trên cổng VNPAY',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // Option A: ATM / Local Bank Card
          _channelRadioTile(
            value: 'ATM',
            icon: Iconsax.bank,
            title: 'Thẻ nội địa & Tài khoản ngân hàng',
            subtitle: 'Hỗ trợ thẻ test NCB (9704198526191432198) & 40+ ngân hàng VN',
            dark: dark,
          ),
          if (_channel == 'ATM') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final bank in _banks)
                  ChoiceChip(
                    selected: _selectedBank == bank.code,
                    selectedColor: _vnpBlue,
                    backgroundColor:
                        dark ? const Color(0xFF1F2E42) : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: _selectedBank == bank.code
                          ? _vnpBlue
                          : (bank.isTestDefault
                              ? _vnpBlue.withValues(alpha: 0.45)
                              : border),
                    ),
                    label: Text(
                      bank.isTestDefault ? '${bank.code} ★ Test' : bank.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedBank == bank.code
                            ? Colors.white
                            : (dark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    onSelected: (_) => setState(() {
                      _selectedBank = bank.code;
                      _rebuildSignedRequest();
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Option B: VNPAY-QR
          _channelRadioTile(
            value: 'VNPAYQR',
            icon: Iconsax.scan_barcode,
            title: 'Ứng dụng thanh toán hỗ trợ VNPAY-QR',
            subtitle: 'Quét mã QR bằng ứng dụng Ngân hàng hoặc Ví VNPAY',
            dark: dark,
          ),
          if (_channel == 'VNPAYQR') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: ShopGlassDecoration(
                color: dark ? const Color(0xFF101D2C) : const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _vnpBlue.withValues(alpha: 0.28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 152,
                    height: 152,
                    padding: const EdgeInsets.all(12),
                    decoration: ShopGlassDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _vnpBlue, width: 2),
                    ),
                    child: CustomPaint(
                      painter: _MockVnPayQrPainter(seed: _txnRef.hashCode),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mã VNPAY-QR Sandbox Test',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: _vnpBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số tiền: ${_formatVnd(widget.amountVnd)} • Hết hạn sau $_formattedTimer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _vnpBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () =>
                          _finishWithCode('00', bankCode: 'VNPAYQR'),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text(
                        'Xác nhận đã quét VNPAY-QR (Test thành công)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Option C: International Card
          _channelRadioTile(
            value: 'INTCARD',
            icon: Iconsax.card,
            title: 'Thẻ thanh toán quốc tế (Visa / Mastercard)',
            subtitle: 'Thanh toán trực tuyến bằng thẻ quốc tế Test Sandbox',
            dark: dark,
          ),

          if (_channel != 'VNPAYQR') ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _vnpBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  _rebuildSignedRequest();
                  setState(() => _step = 1);
                },
                child: Text(
                  'Tiếp tục với ${_channel == 'INTCARD' ? 'Thẻ quốc tế' : 'Ngân hàng $_selectedBank'}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInputStep(Color cardBg, Color border, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShopGlassDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Form(
        key: _cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _channel == 'INTCARD'
                        ? 'Thông tin thẻ quốc tế (Test)'
                        : 'Thông tin thẻ ATM nội địa ($_selectedBank)',
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Đổi kênh'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sandbox Test Card Quick-Fill Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: ShopGlassDecoration(
                color: dark
                    ? const Color(0xFF11293F)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _vnpBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Iconsax.magic_star, size: 16, color: _vnpBlue),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Thẻ Test chuẩn VNPay Sandbox (Ngân hàng NCB)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _vnpBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Số thẻ: 9704198526191432198 • Chủ thẻ: NGUYEN VAN A • Phát hành: 07/15 • OTP: 123456',
                    softWrap: true,
                    style: TextStyle(fontSize: 11.5, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _vnpBlue,
                        side: const BorderSide(color: _vnpBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _fillTestCard,
                      icon: const Icon(Iconsax.flash_1, size: 16),
                      label: const Text(
                        'Điền nhanh thông tin thẻ test VNPay',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.card),
                labelText: 'Số thẻ (Card Number)',
                hintText: '9704198526191432198',
              ),
              validator: (v) {
                final clean = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                if (clean.length < 16) {
                  return 'Số thẻ cần tối thiểu 16 chữ số (Test: 9704198526191432198)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cardHolder,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.user),
                labelText: 'Tên chủ thẻ (Không dấu)',
                hintText: 'NGUYEN VAN A',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên chủ thẻ' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issueDate,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.calendar),
                labelText: _channel == 'INTCARD'
                    ? 'Ngày hết hạn (MM/YY)'
                    : 'Ngày phát hành (MM/YY)',
                hintText: _channel == 'INTCARD' ? '12/28' : '07/15',
              ),
              validator: (v) => (v ?? '').trim().length < 4
                  ? 'Vui lòng nhập định dạng MM/YY (VD: 07/15)'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _vnpBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (_cardFormKey.currentState!.validate()) {
                    setState(() {
                      _otpError = null;
                      _step = 2;
                    });
                  }
                },
                child: const Text(
                  'Tiếp tục xác thực OTP',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep(Color cardBg, Color border, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShopGlassDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Xác thực OTP ngân hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Quay lại'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập mã OTP xác thực giao dịch cho thẻ ${_cardNumber.text.trim()} ($_effectiveBankCode). Trên VNPay Sandbox, mã OTP mặc định là 123456.',
            softWrap: true,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).hintColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '123456',
              errorText: _otpError,
              prefixIcon: const Icon(Iconsax.lock_1),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _otpCtrl.text = VnPaySandboxService.testOtpCode;
                _otpError = null;
              }),
              icon: const Icon(Iconsax.flash_1, size: 15, color: _vnpBlue),
              label: const Text(
                'Điền nhanh OTP mẫu (123456)',
                style: TextStyle(
                  color: _vnpBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _processing ? null : _handleOtpSubmit,
              icon: const Icon(Iconsax.shield_tick, size: 19),
              label: Text(
                'Xác nhận thanh toán ${_formatVnd(widget.amountVnd)}',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelRadioTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool dark,
  }) {
    final selected = _channel == value;
    return Material(
      color: selected
          ? (dark ? const Color(0xFF132C47) : const Color(0xFFEFF6FF))
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? _vnpBlue
              : (dark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _channel = value;
          _rebuildSignedRequest();
        }),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: ShopGlassDecoration(
                  color: selected
                      ? _vnpBlue
                      : (dark
                          ? const Color(0xFF1E2D3D)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : _vnpBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).hintColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _channel,
                activeColor: _vnpBlue,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _channel = v;
                    _rebuildSignedRequest();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _techRow(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _StepIndicatorBar extends StatelessWidget {
  const _StepIndicatorBar({required this.currentStep, required this.dark});

  final int currentStep;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    const labels = ['1. Chọn kênh', '2. Thông tin thẻ', '3. Xác thực OTP'];
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: ShopGlassDecoration(
                color: i <= currentStep
                    ? const Color(0xFF005BAA)
                    : (dark ? const Color(0xFF1A2535) : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i <= currentStep
                      ? const Color(0xFF005BAA)
                      : (dark ? Colors.white12 : const Color(0xFFDCE5F0)),
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: i <= currentStep
                      ? Colors.white
                      : Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _MockVnPayQrPainter extends CustomPainter {
  const _MockVnPayQrPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 15;
    final cell = size.width / grid;
    final paint = Paint()..color = const Color(0xFF003E78);
    final rand = math.Random(seed);

    void drawFinder(int r0, int c0) {
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          final isOuter = r == 0 || r == 4 || c == 0 || c == 4;
          final isInner = r == 2 && c == 2;
          if (isOuter || isInner) {
            canvas.drawRect(
              Rect.fromLTWH((c0 + c) * cell, (r0 + r) * cell, cell, cell),
              paint,
            );
          }
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, grid - 5);
    drawFinder(grid - 5, 0);

    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        final inTopLeft = r < 6 && c < 6;
        final inTopRight = r < 6 && c >= grid - 6;
        final inBotLeft = r >= grid - 6 && c < 6;
        final inCenter = r >= 6 && r <= 8 && c >= 6 && c <= 8;
        if (inTopLeft || inTopRight || inBotLeft || inCenter) continue;
        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell * 0.92, cell * 0.92),
            paint,
          );
        }
      }
    }

    // Center VNPay mini emblem
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cell * 3.1,
      height: cell * 3.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFED1C24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect.deflate(3.5), const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      cell * 0.6,
      Paint()..color = const Color(0xFF005BAA),
    );
  }

  @override
  bool shouldRepaint(covariant _MockVnPayQrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
