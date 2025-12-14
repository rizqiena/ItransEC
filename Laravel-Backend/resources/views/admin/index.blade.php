@extends('layouts.app')

@section('title', 'Kelola Donasi')
@section('page-title', '📊 Dashboard Kelola Donasi')

@section('content')
<div class="container-fluid">
    
    <!-- Action Buttons -->
    <div class="d-flex justify-content-end mb-3">
        <a href="/admin/donasi/programs" class="btn btn-primary me-2">
            <i class="fas fa-cog"></i> Kelola Program
        </a>
        <button class="btn btn-success" onclick="exportExcel()">
            <i class="fas fa-file-excel"></i> Export Excel
        </button>
    </div>

    <!-- Stats Cards -->
    <div class="row mb-4">
        <!-- Total Donasi Hari Ini -->
        <div class="col-md-3 mb-3">
            <div class="stat-card" style="background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white;">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="mb-1" style="opacity: 0.9;">Donasi Hari Ini</h6>
                        <h3 class="mb-0">Rp {{ number_format($stats['today']['total_donasi'], 0, ',', '.') }}</h3>
                        <small style="opacity: 0.8;">↑ 15% dari kemarin</small>
                    </div>
                    <div>
                        <i class="fas fa-money-bill fa-3x" style="opacity: 0.3;"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Total User Hari Ini -->
        <div class="col-md-3 mb-3">
            <div class="stat-card" style="background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); color: white;">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="mb-1" style="opacity: 0.9;">User Hari Ini</h6>
                        <h3 class="mb-0">{{ $stats['today']['total_user'] }} User</h3>
                        <small style="opacity: 0.8;">↑ 3 user baru</small>
                    </div>
                    <div>
                        <i class="fas fa-users fa-3x" style="opacity: 0.3;"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Total Emisi Hari Ini -->
        <div class="col-md-3 mb-3">
            <div class="stat-card" style="background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%); color: white;">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="mb-1" style="opacity: 0.9;">Emisi Ditebus</h6>
                        <h3 class="mb-0">{{ number_format($stats['today']['total_emisi'], 2) }} kg</h3>
                        <small style="opacity: 0.8;">↑ 25 kg dari kemarin</small>
                    </div>
                    <div>
                        <i class="fas fa-leaf fa-3x" style="opacity: 0.3;"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Total Bulan Ini -->
        <div class="col-md-3 mb-3">
            <div class="stat-card" style="background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%); color: white;">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="mb-1" style="opacity: 0.9;">Bulan Ini</h6>
                        <h3 class="mb-0">Rp {{ number_format($stats['this_month']['total_donasi'], 0, ',', '.') }}</h3>
                        <small style="opacity: 0.8;">{{ $stats['this_month']['total_user'] }} transaksi</small>
                    </div>
                    <div>
                        <i class="fas fa-chart-line fa-3x" style="opacity: 0.3;"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Filter Bar -->
    <div class="card mb-4">
        <div class="card-body">
            <form method="GET" action="/admin/donasi" class="row g-3">
                <div class="col-md-3">
                    <select name="program_id" class="form-select">
                        <option value="">Semua Program</option>
                        @foreach($programs as $program)
                            <option value="{{ $program->id }}" {{ request('program_id') == $program->id ? 'selected' : '' }}>
                                {{ $program->icon }} {{ $program->nama_program }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2">
                    <select name="status" class="form-select">
                        <option value="">Semua Status</option>
                        <option value="settlement" {{ request('status') == 'settlement' ? 'selected' : '' }}>✅ Success</option>
                        <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>⏳ Pending</option>
                        <option value="failed" {{ request('status') == 'failed' ? 'selected' : '' }}>❌ Failed</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <input type="date" name="date_from" class="form-control" value="{{ request('date_from') }}" placeholder="Dari">
                </div>
                <div class="col-md-2">
                    <input type="date" name="date_to" class="form-control" value="{{ request('date_to') }}" placeholder="Sampai">
                </div>
                <div class="col-md-3">
                    <div class="input-group">
                        <input type="text" name="search" class="form-control" placeholder="Cari nama/email/ID..." value="{{ request('search') }}">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-search"></i>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Donasi List -->
    <div class="card">
        <div class="card-header bg-white">
            <h5 class="mb-0">📋 Daftar Donasi Terbaru (Total: {{ $donasis->total() }})</h5>
        </div>
        <div class="card-body">
            @if($donasis->isEmpty())
                <div class="text-center py-5">
                    <i class="fas fa-inbox fa-4x text-muted mb-3"></i>
                    <p class="text-muted">Belum ada donasi yang masuk</p>
                    <small class="text-muted">Data donasi akan muncul setelah user melakukan pembayaran</small>
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead class="table-light">
                            <tr>
                                <th>User</th>
                                <th>Program</th>
                                <th>Emisi</th>
                                <th>Nominal</th>
                                <th>Metode</th>
                                <th>Status</th>
                                <th>Tanggal</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($donasis as $donasi)
                                <tr>
                                    <td>
                                        <strong>{{ $donasi->user_name }}</strong><br>
                                        <small class="text-muted">{{ $donasi->user_email }}</small><br>
                                        <small class="text-muted">📱 {{ $donasi->user_phone }}</small>
                                    </td>
                                    <td>
                                        <span class="badge" style="background: #E8F5E9; color: #2E7D32; font-size: 13px;">
                                            {{ $donasi->program->icon ?? '🌱' }} {{ $donasi->program_name }}
                                        </span>
                                    </td>
                                    <td><strong>{{ number_format($donasi->emisi_kg, 2) }} kg</strong></td>
                                    <td><strong>Rp {{ number_format($donasi->nominal_donasi, 0, ',', '.') }}</strong></td>
                                    <td>{{ $donasi->payment_method ?? '-' }}</td>
                                    <td>
                                        @if($donasi->payment_status == 'settlement')
                                            <span class="badge bg-success">✅ Success</span>
                                        @elseif($donasi->payment_status == 'pending')
                                            <span class="badge bg-warning text-dark">⏳ Pending</span>
                                        @else
                                            <span class="badge bg-danger">❌ {{ ucfirst($donasi->payment_status) }}</span>
                                        @endif
                                    </td>
                                    <td>
                                        {{ $donasi->created_at->format('d M Y') }}<br>
                                        <small class="text-muted">{{ $donasi->created_at->format('H:i') }}</small>
                                    </td>
                                    <td>
                                        <a href="{{ route('admin.donasi.detail', $donasi->id) }}" class="btn btn-sm btn-primary">
										<i class="fas fa-eye"></i> Detail
									</a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <div class="mt-3">
                    {{ $donasis->links() }}
                </div>
            @endif
        </div>
    </div>
</div>

@push('scripts')
<script>
function exportExcel() {
    const params = new URLSearchParams(window.location.search);
    window.location.href = '/api/admin/donasi/export?' + params.toString();
}
</script>
@endpush
@endsection