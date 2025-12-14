<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Admin - I-TransEC</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <style>
        /* ... (copy CSS dari app.blade.php) ... */
    </style>
</head>
<body>
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-header">
            <i class="fas fa-leaf fa-3x"></i>
            <h4>I-TransEC Admin</h4>
        </div>
        
        <div class="sidebar-menu">
            <a href="/admin/dashboard" class="active">
                <i class="fas fa-tachometer-alt"></i>
                <span>Dashboard</span>
            </a>
            
            <a href="/admin/berita">
                <i class="fas fa-newspaper"></i>
                <span>Berita</span>
            </a>
            
            <a href="/admin/penerima">
                <i class="fas fa-hands-helping"></i>
                <span>Penerima</span>
            </a>
            
            <a href="/admin/user-acc">
                <i class="fas fa-users"></i>
                <span>User Acc</span>
            </a>
            
            <!-- 🆕 MENU DONASI BARU -->
            <a href="/admin/donasi">
                <i class="fas fa-hand-holding-heart"></i>
                <span>💰 Donasi</span>
            </a>
        </div>
    </div>
    
    <!-- Main Content -->
    <div class="main-content">
        <div class="top-navbar">
            <h4>Dashboard Admin</h4>
            <span>👋 Selamat datang, <strong>Admin</strong></span>
        </div>
        
        <!-- Stats Cards -->
        <div class="row" id="statsContainer">
            <div class="col-md-4">
                <div class="stat-card" style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white;">
                    <h6>Total Berita</h6>
                    <h3 id="totalBerita">0</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card" style="background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%); color: white;">
                    <h6>Penerima</h6>
                    <h3 id="totalPenerima">0</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card" style="background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); color: white;">
                    <h6>User Acc</h6>
                    <h3 id="totalUser">0</h3>
                </div>
            </div>
        </div>
        
        <div class="card mt-4">
            <div class="card-body">
                <h5>Belum ada berita</h5>
            </div>
        </div>
    </div>
    
    <script>
        // Fetch stats dari API
        fetch('/api/admin/stats')
            .then(response => response.json())
            .then(data => {
                if (data.status) {
                    document.getElementById('totalBerita').textContent = data.data.total_berita;
                    document.getElementById('totalPenerima').textContent = data.data.total_penerima;
                    document.getElementById('totalUser').textContent = data.data.total_user;
                }
            })
            .catch(error => console.error('Error:', error));
    </script>
</body>
</html>