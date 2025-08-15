# 🚀 Headscale Admin Dashboard

Một ứng dụng web quản trị hiện đại cho Headscale, cung cấp giao diện trực quan để quản lý servers, users, monitoring và hệ thống.

## ✨ Tính năng chính

### 📊 Dashboard
- **Thống kê tổng quan**: Số lượng servers, users, preauth keys
- **Biểu đồ trực quan**: Server status, network distribution
- **Quick Actions**: Truy cập nhanh các chức năng chính
- **Real-time updates**: Cập nhật dữ liệu theo thời gian thực

### 🖥️ Quản lý Servers (Nodes)
- **Danh sách servers**: Xem tất cả nodes trong hệ thống
- **Chi tiết server**: IP, status, tags, last seen
- **Quản lý tags**: Thêm/sửa/xóa tags cho servers
- **Server operations**: Rename, expire, delete

### 👥 Quản lý Users
- **Danh sách users**: Xem tất cả users
- **Tạo user mới**: Thêm user vào hệ thống
- **Quản lý preauth keys**: Tạo keys cho users
- **User details**: Xem nodes và keys của user

### 📈 Monitoring & Status
- **System Status**: Trạng thái hệ thống Headscale
- **Prometheus Metrics**: Tích hợp với Prometheus
- **Real-time Monitoring**: Theo dõi hiệu suất hệ thống

### 🔐 Authentication
- **Secure Login**: Hệ thống đăng nhập an toàn
- **Session Management**: Quản lý phiên làm việc
- **Password Management**: Đổi mật khẩu

## 🛠️ Cài đặt

### Yêu cầu hệ thống
- Node.js 16+ 
- npm hoặc yarn
- Headscale server đang chạy
- API key từ Headscale

### Bước 1: Cài đặt dependencies
```bash
cd admin-dashboard
npm install
```

### Bước 2: Cấu hình môi trường
```bash
cp env.example .env
```

Chỉnh sửa file `.env`:
```env
# Headscale Configuration
HEADSCALE_URL=https://your-headscale-domain.com
HEADSCALE_API_KEY=your_api_key_here
HEADSCALE_PORT=8080

# Server Configuration
PORT=3001
NODE_ENV=production

# Domain Configuration
DASHBOARD_URL=https://dashboard.tailnet.work

# Security
SESSION_SECRET=your_secure_session_secret
JWT_SECRET=your_secure_jwt_secret
```

### Bước 3: Khởi chạy ứng dụng
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## 🔑 Đăng nhập

**Default credentials:**
- **Username**: `admin`
- **Password**: `password`

⚠️ **Lưu ý**: Đổi mật khẩu ngay sau khi đăng nhập lần đầu!

## 📱 Giao diện

### Responsive Design
- Tương thích với mọi thiết bị
- Sidebar navigation cho desktop
- Mobile-friendly layout

### Modern UI/UX
- Bootstrap 5 framework
- Font Awesome icons
- Chart.js cho biểu đồ
- Gradient backgrounds
- Smooth animations

## 🔌 API Endpoints

### Dashboard
- `GET /` - Dashboard chính
- `GET /status` - System status
- `GET /monitoring` - Monitoring page

### Servers (Nodes)
- `GET /nodes` - Danh sách servers
- `GET /nodes/:id` - Chi tiết server
- `GET /nodes/:id/edit` - Form chỉnh sửa
- `POST /nodes/:id` - Cập nhật server
- `POST /nodes/:id/delete` - Xóa server
- `POST /nodes/:id/expire` - Expire server
- `POST /nodes/:id/rename` - Đổi tên server

### Users
- `GET /users` - Danh sách users
- `GET /users/create` - Form tạo user
- `POST /users` - Tạo user mới
- `GET /users/:id` - Chi tiết user
- `GET /users/:id/edit` - Form chỉnh sửa
- `POST /users/:id` - Cập nhật user
- `POST /users/:id/delete` - Xóa user
- `POST /users/:id/preauthkey` - Tạo preauth key

### API
- `GET /api/stats` - Thống kê dashboard
- `GET /api/nodes` - API nodes
- `GET /api/users` - API users
- `GET /api/status` - API system status
- `GET /api/metrics` - Prometheus metrics

## 🚀 Docker Deployment

### Dockerfile
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  admin-dashboard:
    build: .
    ports:
      - "3001:3001"
    environment:
      - HEADSCALE_URL=https://headscale.internal
      - HEADSCALE_API_KEY=${HEADSCALE_API_KEY}
      - NODE_ENV=production
    restart: unless-stopped
```

## 🔒 Bảo mật

### Session Management
- Secure session cookies
- Session timeout: 24 giờ
- CSRF protection

### Authentication
- bcrypt password hashing
- JWT tokens (optional)
- Secure password policies

### API Security
- API key authentication
- Rate limiting (có thể thêm)
- Input validation

## 📊 Monitoring

### Prometheus Integration
- Metrics collection
- Custom queries
- Performance monitoring

### Real-time Updates
- Socket.IO integration
- Live dashboard updates
- Server status monitoring

## 🐛 Troubleshooting

### Common Issues

1. **Connection refused to Headscale**
   - Kiểm tra HEADSCALE_URL và HEADSCALE_API_KEY
   - Đảm bảo Headscale server đang chạy

2. **Port already in use**
   - Thay đổi PORT trong .env
   - Kiểm tra process đang sử dụng port

3. **API authentication failed**
   - Kiểm tra API key có hợp lệ
   - Kiểm tra quyền truy cập API

### Logs
```bash
# View application logs
npm run dev

# Check system logs
journalctl -u headscale-admin-dashboard
```

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết.

## 🙏 Acknowledgments

- [Headscale](https://github.com/juanfont/headscale) - Open source Tailscale control server
- [Bootstrap](https://getbootstrap.com/) - CSS framework
- [Chart.js](https://www.chartjs.org/) - JavaScript charting library
- [Font Awesome](https://fontawesome.com/) - Icon library

---

**Made with ❤️ for the Headscale community**
