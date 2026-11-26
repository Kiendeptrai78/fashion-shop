# Bảng size sản phẩm

Chi tiết sản phẩm hiển thị trực tiếp **Bảng size tham khảo** dưới phần đánh giá. Bảng chỉ dùng để
đối chiếu: không tự chọn size và không thay đổi tình trạng tồn kho.

Hiện chưa có số đo riêng của các mẫu. App dùng bảng tham khảo chung của shop trong
`ProductSizeGuide.reference`, ghi rõ số đo gần đúng và độ vừa có thể khác giữa các mẫu.
Đây không phải bảng chuẩn của nhà sản xuất. Số đo là chiều dài chân, không phải chiều
dài đế giày. Cần đối chiếu với sản phẩm thực tế trước khi xem là số đo chính thức.

Bảng hiện các size của sản phẩm, kể cả size hết hàng. Nếu sản phẩm chưa có danh sách size, bảng hiện toàn bộ size tham khảo. Size chưa có số đo (ví dụ
size lẻ) hiện **Chưa có số đo**, không nội suy.

Khi có số đo thật, thêm field `SizeGuide` vào document của sản phẩm trên Firestore:

```json
{
  "SizeGuide": {
    "Rows": [
      {"Size": "40", "FootLengthCm": 25.1},
      {"Size": "41", "FootLengthCm": 25.8}
    ],
    "FitNote": "Ghi chú form giày đã được xác nhận cho mẫu này",
    "Source": "Nguồn số đo thực tế",
    "IsReference": false
  }
}
```

Các số trong JSON trên chỉ minh họa schema, không phải số đo sản phẩm. Bảng riêng có
dữ liệu sẽ thay bảng chung; các size bị thiếu trong bảng riêng vẫn hiện chưa có số đo.
Document cũ không cần cập nhật. Bảng mặc định không tự ghi vào Firestore.
