class TFirebaseAuthException implements Exception {
  final String code;

  TFirebaseAuthException(this.code);

  String get message {
    switch (code) {
      case 'email-already-in-use':
      case 'email already in use':
        return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      case 'too-many-requests':
        return 'Thử đăng nhập quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập Email/Mật khẩu chưa được bật trong Firebase Console.';
      default:
        return 'Lỗi xác thực Firebase ($code). Vui lòng thử lại.';
    }
  }
}
