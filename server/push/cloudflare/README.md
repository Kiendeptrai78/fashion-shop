# VELORA cloud push

Triển khai ngày 26/11/2026 trên tài khoản Free ($0), lịch mỗi phút. Đã tắt và disable
worker Mac; cron cloud gửi thông báo kiểm tra với FCM accepted=1, errors=0, và chủ
tài khoản xác nhận iPhone đã nhận. Dashboard hiện Free là Current plan.

Cloudflare Workers Free chạy cron `* * * * *`. Không cần Mac, Firebase Functions,
Firebase billing hoặc máy chủ Node chạy liên tục. Dùng OAuth service account,
Firestore REST và FCM HTTP v1. Nội dung thông báo dùng chung `../messages.mjs`.

## Vận hành

- Tên Worker: `velora-push`.
- Account Cloudflare: `2f676a39b0ec5542c85e18986769b802`.
- Dashboard: https://dash.cloudflare.com/2f676a39b0ec5542c85e18986769b802/workers/services/view/velora-push/production
- `FIREBASE_SERVICE_ACCOUNT`: Secret chứa JSON service account, không phải biến
  plaintext trong Wrangler config. Không commit file này hoặc token Wrangler.
- `PUSH_ENABLED=true` bật xử lý. Đổi thành `false` rồi deploy để tạm dừng.
- HTTP chỉ trả health text, không đọc dữ liệu và không kích hoạt gửi thông báo.

```sh
cd server/push/cloudflare
npm ci
npm test
npm run deploy
npx wrangler tail velora-push --format pretty
```

Nếu cần cài Secret trên tài khoản mới, truyền file riêng qua stdin của
`wrangler secret put FIREBASE_SERVICE_ACCOUNT`; không đưa nội dung khóa vào chat,
tham số dòng lệnh, source, config, log hoặc app Flutter.

## Cách xử lý

1. Mỗi phút query các Notifications có `pushPending=true`, Orders và Products có
   `notificationPending=true`. Các index nằm trong root `firestore.indexes.json`.
2. Claim job bằng lease 90 giây và Firestore document-version precondition. Nhiều
   lần cron hoặc thay đổi trạng thái Admin không được ghi đè dữ liệu mới hơn.
3. Gửi đúng thiết bị bật push và ngôn ngữ đã lưu; sản phẩm mới chỉ gửi tới danh mục
   thiết bị theo dõi. Không fallback thông báo riêng tư sang topic công khai.
4. Chỉ đánh dấu hoàn tất sau FCM chấp nhận. Lỗi mạng/quota giữ job để vòng sau thử
   lại. Token UNREGISTERED bị tắt, không đánh dấu thông báo đã gửi nếu không có
   thiết bị hợp lệ. FCM chấp nhận không chứng minh banner đã hiện trên iPhone.
5. Notice ID dùng chung inbox/order source và collapse ID giữ ổn định. FCM không
   bảo đảm exactly-once; crash sau khi gửi nhưng trước khi ghi complete có thể gửi
   lại. Không chạy worker Mac song song khi cloud đã bật.

## Hạn mức miễn phí

Tải hiện tại nhỏ. Khi hàng đợi rỗng, bốn query mỗi phút tương đương khoảng 5.760
Firestore reads/ngày (chưa tính app/admin, index reads và job thực tế). Không quét
toàn bộ người dùng hoặc catalog mỗi phút. Mỗi lượt giới hạn 40 API calls, có chừa
phần cho OAuth dưới ngưỡng 50 subrequests của Workers Free; dư job giữ sang lượt
sau. Mỗi query hiện giới hạn 100 documents; cần bổ sung phân trang khi tăng quy mô
thay vì khẳng định hỗ trợ catalog/thiết bị không giới hạn.

Workers Free có CPU budget 10 ms/lượt; tác vụ lớn hoặc quá quota có thể thất bại và
được thử lại lượt sau. Cron không phải cam kết giao đúng trong 60 giây. Một số thay
đổi Cron Trigger có thể cần tới 15 phút để lan truyền. Không bật Workers Paid.

## Chuyển từ bản Mac

Mốc lịch sử lần cài dịch vụ Mac được lưu riêng trong Application Support. Khi
chuyển cloud, chỉ các cờ pending còn nguyên phiên bản từ trước mốc đó được bỏ và
gắn `pushSkippedReason=historical_queue_before_cloud_migration`; nội dung hộp thông
báo được giữ nguyên. Danh sách migration có metadata phục hồi nằm ngoài Git.
Thông báo mới không dùng `--new-only` và không bị bỏ qua lúc cloud khởi động lại.

Dịch vụ Mac `com.velora.push-worker` phải bootout và disable. Rollback: pause cloud
trước, sau đó `launchctl enable gui/$(id -u)/com.velora.push-worker` và bootstrap
LaunchAgent đã cài. Không chạy lại hai bản cùng lúc.

Nguồn chính thức:
- https://developers.cloudflare.com/workers/configuration/cron-triggers/
- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/workers/configuration/secrets/
- https://firebase.google.com/docs/firestore/quotas

## Nhắc đánh giá

Khi xử lý đơn received, worker tạo job ReviewReminders cố định theo đường dẫn đơn,
hẹn sau 24 giờ. Cron query dueAt bằng timestamp (collection index tự động), đọc lại
đơn trước khi gửi; chỉ nhắc một lần nếu còn sản phẩm chưa đánh giá. Sau xử lý job
có dueAt=null và được giữ để đối soát. Notification kind review_reminder mở chi tiết
đơn; nếu khách đã đánh giá trong lúc thông báo còn chờ, worker bỏ gửi. Không quét
hoặc nhắc hồi tố mọi đơn lịch sử.
