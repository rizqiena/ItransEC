<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Models\Payment;
use App\Models\Donasi;
use App\Models\ProgramDonasi;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    private $serverKey;
    private $clientKey;
    private $isProduction;
    private $snapUrl;

    public function __construct()
    {
        $this->serverKey = config('midtrans.server_key');
        $this->clientKey = config('midtrans.client_key');
        $this->isProduction = config('midtrans.is_production', false);

        // Snap API URL
        $this->snapUrl = $this->isProduction
            ? 'https://app.midtrans.com/snap/v1/transactions'
            : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

        Log::info('🔧 PaymentController Init', [
            'server_key' => $this->serverKey ? substr($this->serverKey, 0, 20) . '...' : null,
            'is_production' => $this->isProduction,
            'snap_url' => $this->snapUrl,
        ]);
    }

    /**
     * Create payment (store pending payment + call Midtrans Snap)
     * 🆕 UPDATED: Sekarang bisa terima program_id dan program_name untuk Tebus Emisi
     */
    public function createPayment(Request $request)
    {
        try {
            $orderId = 'TRX-' . date('Ymd') . '-' . strtoupper(Str::random(8));

            Log::info('🔵 [PaymentController] createPayment called', [
                'order_id' => $orderId,
                'request_data' => $request->all(),
            ]);

            // ========================================
            // VALIDASI INPUT (SUPPORT MULTIPLE FORMATS)
            // ========================================
            $validated = $request->validate([
                'amount' => 'required|numeric|min:1',
                'emisi' => 'nullable|numeric|min:0',
                'emisi_kg' => 'nullable|numeric|min:0',
                'name' => 'nullable|string|max:255',
                'customer_name' => 'nullable|string|max:255',
                'email' => 'nullable|email|max:255',
                'customer_email' => 'nullable|email|max:255',
                'phone' => 'nullable|string|max:20',
                'customer_phone' => 'nullable|string|max:20',
                'program_id' => 'nullable|integer',
                'program_name' => 'nullable|string|max:255',
            ]);

            // ========================================
            // NORMALIZE FIELD NAMES
            // ========================================
            $emisiKg = $validated['emisi_kg'] ?? $validated['emisi'] ?? 0;
            $customerName = $validated['customer_name'] ?? $validated['name'] ?? 'Guest';
            $customerEmail = $validated['customer_email'] ?? $validated['email'] ?? 'guest@example.com';
            $customerPhone = $validated['customer_phone'] ?? $validated['phone'] ?? '0000000000';
            $programId = $validated['program_id'] ?? null;
            $programName = $validated['program_name'] ?? 'Program Donasi';

            Log::info('✅ [PaymentController] Data normalized', [
                'order_id' => $orderId,
                'emisi_kg' => $emisiKg,
                'customer_name' => $customerName,
                'program_id' => $programId,
                'program_name' => $programName,
            ]);

            // ========================================
            // 1. SIMPAN KE TABLE PAYMENTS (EXISTING)
            // ========================================
            $payment = Payment::create([
                'order_id' => $orderId,
                'amount' => $validated['amount'],
                'emisi' => $emisiKg,
                'customer_name' => $customerName,
                'email' => $customerEmail,
                'phone' => $customerPhone,
                'transaction_status' => 'pending',
            ]);

            Log::info('💾 [PaymentController] Payment record created', [
                'payment_id' => $payment->id,
            ]);

            // ========================================
            // 2. SIMPAN KE TABLE DONASIS (NEW)
            // ========================================
            $ratePerKg = $emisiKg > 0 ? $validated['amount'] / $emisiKg : 1000;

            $donasi = Donasi::create([
                'user_name' => $customerName,
                'user_email' => $customerEmail,
                'user_phone' => $customerPhone,
                'emisi_kg' => $emisiKg,
                'nominal_donasi' => $validated['amount'],
                'rate_per_kg' => $ratePerKg,
                'program_id' => $programId,
                'program_name' => $programName,
                'transaction_id' => $orderId,
                'midtrans_order_id' => $orderId,
                'payment_method' => null,
                'payment_status' => 'pending',
                'payment_time' => null,
                'payment_response' => null,
            ]);

            Log::info('💾 [PaymentController] Donasi record created', [
                'donasi_id' => $donasi->id,
                'program_id' => $donasi->program_id,
                'program_name' => $donasi->program_name,
            ]);

            // ========================================
            // 3. CALL MIDTRANS SNAP API
            // ========================================
            // Nama item dinamis berdasarkan program
            $itemName = 'Pembayaran Offset Emisi Karbon - ' . $emisiKg . ' Kg CO₂';
            if (!empty($programName) && $programName !== 'Program Donasi') {
                $itemName = 'Tebus Emisi ' . $emisiKg . ' Kg - ' . $programName;
            }

            $params = [
                'transaction_details' => [
                    'order_id' => $orderId,
                    'gross_amount' => (int) $validated['amount'],
                ],
                'customer_details' => [
                    'first_name' => $customerName,
                    'email' => $customerEmail,
                    'phone' => $customerPhone,
                ],
                'item_details' => [
                    [
                        'id' => 'EMISI-' . $orderId,
                        'price' => (int) $validated['amount'],
                        'quantity' => 1,
                        'name' => $itemName,
                    ],
                ],
            ];

            Log::info('📤 [PaymentController] Sending to Midtrans', [
                'url' => $this->snapUrl,
                'params' => $params,
            ]);

            // Call Midtrans Snap API
            $response = Http::timeout(30)
                ->withHeaders([
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'Authorization' => 'Basic ' . base64_encode($this->serverKey . ':'),
                ])
                ->withOptions(['verify' => false])
                ->post($this->snapUrl, $params);

            Log::info('📥 [PaymentController] Midtrans Response', [
                'status_code' => $response->status(),
                'body' => $response->body(),
            ]);

            if (!$response->successful()) {
                $errorBody = $response->json();

                Log::error('❌ [PaymentController] Midtrans API Error', [
                    'status' => $response->status(),
                    'error' => $errorBody,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Midtrans Error: ' . ($errorBody['error_messages'][0] ?? 'Unknown error'),
                ], 500);
            }

            $data = $response->json();
            $redirectUrl = $data['redirect_url'] ?? null;

            if (!$redirectUrl) {
                Log::error('❌ [PaymentController] No redirect_url', ['response' => $data]);
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak mendapat URL pembayaran dari Midtrans',
                ], 500);
            }

            Log::info('✅ [PaymentController] Payment Created Successfully', [
                'order_id' => $orderId,
                'redirect_url' => $redirectUrl,
                'token' => $data['token'] ?? null,
                'donasi_id' => $donasi->id,
            ]);

            return response()->json([
                'success' => true,
                'order_id' => $orderId,
                'redirect_url' => $redirectUrl,
                'token' => $data['token'] ?? null,
                'donasi_id' => $donasi->id,
                'message' => 'Transaksi berhasil dibuat',
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::error('❌ [PaymentController] Validation failed', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $e->errors(),
            ], 422);

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('❌ [PaymentController] Connection Error', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Koneksi ke Midtrans gagal: ' . $e->getMessage(),
            ], 500);

        } catch (\Exception $e) {
            Log::error('❌ [PaymentController] Error', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => substr($e->getTraceAsString(), 0, 1000),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat payment: ' . $e->getMessage(),
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Midtrans callback (webhook)
     * 🆕 UPDATED: Sekarang juga update table donasis
     */
    public function callback(Request $request)
    {
        Log::info('📨 [PaymentController] Midtrans Callback', $request->all());

        $serverKey = $this->serverKey;
        $orderId = $request->order_id;
        $statusCode = $request->status_code;
        $grossAmount = $request->gross_amount;
        $signatureKey = $request->signature_key;

        // Verify signature
        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($expectedSignature !== $signatureKey) {
            Log::warning('⚠️ [PaymentController] Invalid Signature', [
                'order_id' => $orderId,
                'expected' => $expectedSignature,
                'received' => $signatureKey,
            ]);

            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $transactionStatus = $request->transaction_status;
        $paymentType = $request->payment_type ?? null;

        Log::info('✅ [PaymentController] Callback Verified', [
            'order_id' => $orderId,
            'status' => $transactionStatus,
            'payment_type' => $paymentType,
        ]);

        // ========================================
        // 1. UPDATE TABLE PAYMENTS (EXISTING)
        // ========================================
        $payment = Payment::where('order_id', $orderId)->first();
        if ($payment) {
            $payment->transaction_status = $transactionStatus;
            $payment->save();
            Log::info('💾 [PaymentController] Payment status updated', [
                'order_id' => $orderId,
                'status' => $transactionStatus,
            ]);
        } else {
            Log::warning('⚠️ [PaymentController] Payment not found', ['order_id' => $orderId]);
        }

        // ========================================
        // 2. UPDATE TABLE DONASIS (NEW)
        // ========================================
        $donasi = Donasi::where('transaction_id', $orderId)->first();

        if ($donasi) {
            // Update payment method
            if ($paymentType) {
                $donasi->payment_method = $paymentType;
            }

            // Update status based on Midtrans response
            if ($transactionStatus == 'capture' || $transactionStatus == 'settlement') {
                $donasi->payment_status = 'settlement';
                $donasi->payment_time = now();

                Log::info('✅ [PaymentController] Donasi payment SUCCESS', [
                    'donasi_id' => $donasi->id,
                    'program_id' => $donasi->program_id,
                    'emisi_kg' => $donasi->emisi_kg,
                    'nominal' => $donasi->nominal_donasi,
                ]);

                // ========================================
                // 3. UPDATE TOTAL DONASI DI PROGRAM
                // ========================================
                if ($donasi->program_id) {
                    $program = ProgramDonasi::find($donasi->program_id);
                    if ($program) {
                        $oldTotal = $program->total_donasi_masuk;
                        $program->total_donasi_masuk += $donasi->nominal_donasi;
                        $program->save();

                        Log::info('💰 [PaymentController] Program donasi updated', [
                            'program_id' => $program->id,
                            'program_name' => $program->nama_program,
                            'total_before' => $oldTotal,
                            'added' => $donasi->nominal_donasi,
                            'total_after' => $program->total_donasi_masuk,
                        ]);
                    }
                }

            } elseif ($transactionStatus == 'pending') {
                $donasi->payment_status = 'pending';
            } elseif (in_array($transactionStatus, ['deny', 'expire', 'cancel'])) {
                $donasi->payment_status = 'failed';
                Log::warning('❌ [PaymentController] Donasi payment FAILED', [
                    'donasi_id' => $donasi->id,
                    'status' => $transactionStatus,
                ]);
            }

            // Simpan raw response dari Midtrans
            $donasi->payment_response = json_encode($request->all());
            $donasi->save();

            Log::info('💾 [PaymentController] Donasi status updated', [
                'donasi_id' => $donasi->id,
                'status' => $donasi->payment_status,
            ]);
        } else {
            Log::warning('⚠️ [PaymentController] Donasi not found', ['order_id' => $orderId]);
        }

        return response()->json(['message' => 'Callback processed'], 200);
    }

    /**
     * Get user's payment history
     */
    public function myPayments(Request $request)
    {
        try {
            $user = $request->user();

            $payments = Payment::where('email', $user->Email_Masyarakat)
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $payments,
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [PaymentController] Get my payments error', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Check status via Midtrans API (manual)
     */
    public function checkStatus($orderId)
    {
        try {
            $statusUrl = $this->isProduction
                ? "https://api.midtrans.com/v2/{$orderId}/status"
                : "https://api.sandbox.midtrans.com/v2/{$orderId}/status";

            Log::info('🔍 [PaymentController] Checking Status', [
                'order_id' => $orderId,
                'url' => $statusUrl,
            ]);

            $response = Http::timeout(30)
                ->withHeaders([
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'Authorization' => 'Basic ' . base64_encode($this->serverKey . ':'),
                ])
                ->withOptions(['verify' => false])
                ->get($statusUrl);

            if (!$response->successful()) {
                Log::error('❌ [PaymentController] Check Status Failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Gagal cek status: ' . $response->body(),
                ], 500);
            }

            $data = $response->json();

            Log::info('✅ [PaymentController] Status Retrieved', $data);

            return response()->json([
                'success' => true,
                'data' => $data,
            ], 200);

        } catch (\Exception $e) {
            Log::error('❌ [PaymentController] Check Status Error', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get total emisi dari table payments
     */
    public function getTotalEmisi(Request $request)
    {
        try {
            $user = $request->user();

            $totalEmisi = Payment::where('email', $user->Email_Masyarakat)
                ->where('transaction_status', 'settlement')
                ->sum('emisi');

            return response()->json([
                'success' => true,
                'total_emisi' => $totalEmisi,
                'email' => $user->Email_Masyarakat,
            ]);

        } catch (\Exception $e) {
            Log::error('❌ [PaymentController] Get Total Emisi Error', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }
}