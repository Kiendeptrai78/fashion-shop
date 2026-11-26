# Xu VELORA

- 1 xu = 1 VND. Đánh giá mua hàng lần đầu nhận 1.000 xu cho mỗi sản phẩm trong mỗi
  đơn đã giao thành công. Gửi lần hai bị từ chối, không lưu thêm đánh giá hay cộng xu.
- Đơn đã đánh giá hết sản phẩm sẽ ẩn nút đánh giá ở danh sách; chi tiết đơn hiện đã đánh giá và khóa thao tác cho sản phẩm đó. Đơn nhiều sản phẩm còn sản phẩm chưa đánh giá vẫn hiện nút.
- Đánh giá cũ có liên kết đơn hàng được đồng bộ cờ đã đánh giá, không thưởng hồi tố.
- Checkout mặc định không dùng xu. Khi bật, dùng tối đa số dư và không vượt số tiền
  còn phải trả sau hai loại voucher. Tiền nội bộ vẫn lưu USD, phần giảm xu đổi bằng
  `usdToVnd`; xu và giá trị giảm VND luôn lưu số nguyên.
- Tạo đơn và trừ xu cùng một Firestore transaction. Hủy đơn qua khách hàng hoặc
  admin hoàn xu cùng transaction cập nhật trạng thái, có cờ chống hoàn hai lần.

## Dữ liệu

| Đường dẫn | Nội dung |
| --- | --- |
| `Users/{uid}/Wallet/coins` | `balance` (int), `updatedAt` |
| `Users/{uid}/Orders/{doc}/ReviewRewards/{product}` | `amount`, `reviewId`, `createdAt` |
| `Users/{uid}/Orders/{doc}` | `reviewedProductIds`, `coinsUsed`, `coinDiscountVnd`, `coinsRefunded` |

Đánh giá, cờ đã đánh giá và phần thưởng được ghi chung một transaction. Ví được
nghe realtime ở Settings và Checkout, không dùng chung ví ngân hàng trước đây.
Đơn và tài khoản cũ không có ví bắt đầu với 0 xu.

## Xác minh

Test giao dịch dùng `fake_cloud_firestore`, không cộng/trừ trên tài khoản thật.
Các test không xác minh Security Rules đang triển khai. Repo chưa quản lý ruleset
Firestore hiện hành; các giao dịch này chạy qua SDK của khách hàng và phụ thuộc vào
rules của dự án. Trước khi dùng cho thanh toán thật, cần kiểm tra rules bảo vệ ví,
thưởng và ghi đơn để khách hàng không thể sửa số dư hay tự tạo thưởng tùy ý.

## Nhắc đánh giá

Cloud lên lịch nhắc một lần sau 24 giờ kể từ khi xử lý trạng thái đã giao. Job riêng
`ReviewReminders` được tạo bằng ID cố định theo đường dẫn đơn. Trước khi gửi, cloud
đọc lại trạng thái đơn và các sản phẩm đã đánh giá; đơn hủy hoặc đã đánh giá hết sẽ
bỏ nhắc. Chạm thông báo mở chi tiết đơn. Không áp dụng hồi tố hàng loạt cho đơn cũ.
