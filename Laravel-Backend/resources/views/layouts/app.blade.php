<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Dashboard') - I-TransEC</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <style>
        :root {
            --primary-color: #4CAF50;
            --secondary-color: #45a049;
            --sidebar-width: 250px;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
        }
        
        .sidebar {
            position: fixed;
            top: 0;
            left: 0;
            height: 100vh;
            width: var(--sidebar-width);
            background: linear-gradient(135deg, #2E7D32 0%, #4CAF50 100%);
            color: white;
            overflow-y: auto;
            z-index: 1000;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
        }
        
        .sidebar-header {
            padding: 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .sidebar-header h4 {
            margin: 10px 0 0 0;
            font-weight: 600;
        }
        
        .sidebar-menu {
            padding: 20px 0;
        }
        
        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 12px 20px;
            color: white;
            text-decoration: none;
            transition: all 0.3s;
        }
        
        .sidebar-menu a:hover {
            background: rgba(255,255,255,0.1);
            padding-left: 30px;
        }
        
        .sidebar-menu a.active {
            background: rgba(255,255,255,0.2);
            border-left: 4px solid white;
        }
        
        .sidebar-menu a i {
            margin-right: 10px;
            width: 20px;
            text-align: center;
        }
        
        .main-content {
            margin-left: var(--sidebar-width);
            padding: 20px;
            min-height: 100vh;
        }
        
        .top-navbar {
            background: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 20px;
        }
        
        .stat-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        
        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }
            
            .sidebar.show {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0;
            }
        }
    </style>
    
    @stack('styles')
</head>
<body>
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-header">
            <i class="fas fa-leaf fa-3x"></i>
            <h4>I-TransEC Admin</h4>
        </div>
        
        <div class="sidebar-menu">
            <a href="/admin/dashboard" class="{{ request()->is('admin/dashboard') ? 'active' : '' }}">
                <i class="fas fa-tachometer-alt"></i>
                <span>Dashboard</span>
            </a>
            
            <a href="/admin/berita" class="{{ request()->is('admin/berita*') ? 'active' : '' }}">
                <i class="fas fa-newspaper"></i>
                <span>Berita</span>
            </a>
            
            <a href="/admin/penerima" class="{{ request()->is('admin/penerima*') ? 'active' : '' }}">
                <i class="fas fa-hands-helping"></i>
                <span>Penerima</span>
            </a>
            
            <a href="/admin/user-acc" class="{{ request()->is('admin/user-acc*') ? 'active' : '' }}">
                <i class="fas fa-users"></i>
                <span>User Acc</span>
            </a>
            
            <!-- 🆕 MENU DONASI BARU -->
            <a href="/admin/donasi" class="{{ request()->is('admin/donasi*') ? 'active' : '' }}">
                <i class="fas fa-hand-holding-heart"></i>
                <span>💰 Donasi</span>
            </a>
            
            <hr style="border-color: rgba(255,255,255,0.2); margin: 20px;">
            
            <a href="/admin/settings">
                <i class="fas fa-cog"></i>
                <span>Pengaturan</span>
            </a>
            
            <a href="/logout" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
            <form id="logout-form" action="/logout" method="POST" style="display: none;">
                @csrf
            </form>
        </div>
    </div>
    
    <!-- Main Content -->
    <div class="main-content">
        <!-- Top Navbar -->
        <div class="top-navbar">
            <div>
                <h4 class="mb-0">@yield('page-title', 'Dashboard')</h4>
            </div>
            <div>
                <span class="text-muted">👋 Selamat datang, <strong>Admin</strong></span>
            </div>
        </div>
        
        <!-- Page Content -->
        @yield('content')
    </div>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    @stack('scripts')
</body>
</html>