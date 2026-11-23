import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/data/repositories/authentication/authentication_repository.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';

class OrderRepository extends GetxController{
  static OrderRepository get instance => Get.find();

  Future<void> updateCustomerStatus(OrderModel order, OrderStatus next) async {
    final uid = AuthenticationRepository.instance.authUser.uid;
    final result = await _db.collection('Users').doc(uid).collection('Orders')
        .where('id', isEqualTo: order.id).limit(1).get();
    if (result.docs.isEmpty) throw StateError('Order no longer exists.');
    final ref = result.docs.single.reference;
    await _db.runTransaction((transaction) async {
      final current = (await transaction.get(ref)).data();
      final status = current?['status'];
      final canCancel =
          next == OrderStatus.cancelled && status == OrderStatus.pending.toString();
      final canReceive = next == OrderStatus.received && status == OrderStatus.shipped.toString();
      if (!canCancel && !canReceive) throw StateError('Order status has changed. Refresh and try again.');
      transaction.update(ref, {'status': next.toString(), 'notificationPending': true});
    });
    await _writeCustomerOrderNotification(uid: uid, order: order, status: next);
  }

  Future<void> _writeCustomerOrderNotification({
    required String uid,
    required OrderModel order,
    required OrderStatus status,
  }) async {
    try {
      final viItems = order.itemsSummary(english: false);
      final enItems = order.itemsSummary(english: true);
      final thumb = order.items.isNotEmpty ? (order.items.first.image ?? '') : '';
      final (titleVi, titleEn, bodyVi, bodyEn) = switch (status) {
        OrderStatus.pending => (
            'Đặt hàng thành công: $viItems',
            'Order placed: $enItems',
            'Đơn hàng của bạn đã được gửi tới VELORA và đang chờ xác nhận.',
            'Your order has been sent to VELORA and is awaiting confirmation.',
          ),
        OrderStatus.processing => (
            'Đơn hàng $viItems của bạn đang được chuẩn bị',
            'Your order for $enItems is being prepared',
            'VELORA đang kiểm tra và đóng gói sản phẩm cho bạn.',
            'VELORA is checking and packing your items.',
          ),
        OrderStatus.shipped => (
            'Đơn hàng $viItems của bạn đang trên đường giao',
            'Your order for $enItems is on the way',
            'Đơn hàng đã bàn giao cho đơn vị vận chuyển.',
            'Your order has been handed to the carrier.',
          ),
        OrderStatus.received => (
            'Bạn đã nhận đơn hàng $viItems',
            'You received your order for $enItems',
            'Cảm ơn bạn đã mua sắm tại VELORA! Hãy đánh giá sản phẩm để nhận thêm gợi ý chuẩn gu nhé.',
            'Thank you for shopping with VELORA! You can now review your pair.',
          ),
        OrderStatus.cancelled => (
            'Đơn hàng $viItems của bạn đã hủy',
            'Your order for $enItems was cancelled',
            'Đơn hàng đã chuyển sang trạng thái hủy.',
            'Your order has been cancelled.',
          ),
      };
      final notifId = 'order-${order.id}-${status.name}';
      await _db.collection('Users').doc(uid).collection('Notifications').doc(notifId).set({
        'id': notifId,
        'kind': 'order',
        'targetId': order.id,
        'imageUrl': thumb,
        'titleVi': titleVi,
        'titleEn': titleEn,
        'bodyVi': bodyVi,
        'bodyEn': bodyEn,
        'read': false,
        'pushPending': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-blocking notification write.
    }
  }

  ///variable
  final _db = FirebaseFirestore.instance;

  List<OrderModel> temporaryOrders = [];

/// Fetch all orders for all users
  Future<List<OrderModel>> fetchAllUserOrders() async {
    try {
      // Get all user documents
      final usersSnapshot = await _db.collection('Users').get();

      List<OrderModel> allOrders = [];

      // Iterate through each user document to get their orders
      for (var userDoc in usersSnapshot.docs) {
        final ordersSnapshot = await _db
            .collection('Users')
            .doc(userDoc.id)
            .collection('Orders')
            .get();

        // Add each order to the list
        allOrders.addAll(ordersSnapshot.docs.map((e) => OrderModel.fromSnapshot(e)).toList());
      }

      return allOrders;
    } catch (e) {
      print('Error fetching all user orders: $e');
      throw 'Something went wrong while fetching all user orders. Try again later';
    }
  }

  Stream<List<OrderModel>> getOrderStream() {
    return _db.collection('Orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromQuerySnapshot(doc)).toList();
    });
  }

  ///xoa

  Future<void> deleteOrder(String userId ,String orderId,) async {
    try {
      final orderDoc = await _db.collection('Users').doc(userId).collection('Orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw 'Order does not exist in user\'s collection.';
      }

      // Xóa đơn hàng từ subcollection của người dùng
      await _db.collection('Users').doc(userId).collection('Orders').doc(orderId).delete();

      // Xóa đơn hàng từ collection chính nếu nó tồn tại ở đó
      final mainOrderDoc = await _db.collection('Orders').doc(orderId).get();
      if (mainOrderDoc.exists) {
        await _db.collection('Orders').doc(orderId).delete();
      }

      print('Order successfully deleted');
    } catch (e) {
      print('Error deleting order: $e');
      // Thông báo lỗi chi tiết cho người dùng
      throw 'Failed to delete order: $e';
    }
  }

  ///get order related to current user
  Future<List<OrderModel>> fetchUserOrders() async{
    try{
      final userId = AuthenticationRepository.instance.authUser.uid;
      if(userId.isEmpty) throw 'Unable to find user information. Try again in few minutes.';

      final result = await _db.collection('Users').doc(userId).collection('Orders').get();
      return result.docs.map((e) => OrderModel.fromSnapshot(e)).toList();
    }catch(e){
      throw 'Something went wrong while fetching order information. Try again later';
    }
  }
  Future<List<OrderModel>> fetchUserOrders2(String userId) async {
    try {
      final result = await _db.collection('Users').doc(userId).collection('Orders').get();
      return result.docs.map((e) => OrderModel.fromSnapshot(e)).toList();
    } catch (e) {
      throw 'Something went wrong while fetching order information. Try again later';
    }
  }

// New method to fetch all orders for admin

  Future<List<OrderModel>> fetchUserOrdersAdmin(String userId) async {
    try {
      if (userId.isEmpty) throw 'Unable to find user information. Try again in a few minutes.';

      final result = await _db.collection('Users').doc(userId).collection('Orders').get();
      return result.docs.map((e) => OrderModel.fromSnapshot(e)).toList();
    } catch (e) {
      throw 'Something went wrong while fetching order information. Try again later';
    }
  }

  Future<List<OrderModel>> fetchUserOrdersAdmin2(String userId, {String? orderId}) async {
    try {
      if (userId.isEmpty) {
        throw 'Unable to find user information. Try again in a few minutes.';
      }

      // Tham chiếu đến bộ sưu tập đơn hàng của người dùng
      final ordersCollection = _db.collection('Users').doc(userId).collection('Orders');

      // Kiểm tra nếu orderId được cung cấp
      final QuerySnapshot result;
      if (orderId != null) {
        // Lấy đơn hàng cụ thể dựa trên orderId
        result = await ordersCollection.where('id', isEqualTo: orderId).get();
      } else {
        // Lấy tất cả các đơn hàng nếu không có orderId
        result = await ordersCollection.get();
      }

      // Chuyển đổi kết quả thành danh sách các OrderModel
      return result.docs.map((e) => OrderModel.fromSnapshot(e)).toList();
    } catch (e) {
      throw 'Something went wrong while fetching order information. Try again later';
    }
  }


  //save and update orders
  Future<String> saveOrUpdateOrder(OrderModel order, String clientUserId) async {
    try {
      final orderRef = _db.collection('Users').doc(clientUserId).collection('Orders');

      // Kiểm tra xem đơn hàng đã tồn tại hay chưa
      final querySnapshot = await orderRef.where('id', isEqualTo: order.id).get();
      if (querySnapshot.docs.isEmpty) {
        // Nếu đơn hàng chưa tồn tại, thêm mới đơn hàng
        final docRef = await orderRef.add({...order.toJson(), 'notificationPending': true});
        await _writeCustomerOrderNotification(uid: clientUserId, order: order, status: order.status);
        return docRef.id;
      } else {
        // Nếu đơn hàng đã tồn tại, cập nhật đơn hàng
        final orderId = querySnapshot.docs.first.id;
        await orderRef.doc(orderId).update({...order.toJson(), 'notificationPending': true});
        await _writeCustomerOrderNotification(uid: clientUserId, order: order, status: order.status);
        return orderId;
      }
    } catch (e) {
      throw 'Failed to save or update order: $e';
    }
  }

  Future<List<OrderModel>> fetchReceivedOrders() async {
    try {
      List<OrderModel> receivedOrders = [];

      // Lấy ngày hôm nay
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Lấy tất cả các tài liệu người dùng
      final usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();

      // Lặp qua từng tài liệu người dùng để tìm đơn hàng có trạng thái "Received" và searchDate là ngày hôm nay
      for (var userDoc in usersSnapshot.docs) {
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('Orders')
            .where('status', isEqualTo: 'OrderStatus.received')
            .get();

        // Thêm các đơn hàng có trạng thái "Received" và searchDate là ngày hôm nay vào danh sách
        receivedOrders.addAll(ordersSnapshot.docs.map((e) => OrderModel.fromSnapshot(e)).toList());
      }

      return receivedOrders;
    } catch (e) {
      print('Error fetching received orders: $e'); // In lỗi chi tiết
      throw 'Something went wrong while fetching received orders. Try again later';
    }
  }


  // Phương thức để thêm đơn đặt hàng vào biến tạm thời
  void addTemporaryOrders(List<OrderModel> orders) {
    temporaryOrders.addAll(orders);
  }
}