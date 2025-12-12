<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Models\Payment; // <== PASTIKAN MODEL ADA

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
     */
    public function createPayment(Request $request)
    {
        $orderId = 'ORDER-' . time() . '-' . rand(1000, 9999);

        Log::info('🚀 CREATE PAYMENT REQUEST', [
            'order_id' => $orderId,
            'amount' => $request->amount,
            'emisi' => $request->emisi,
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
        ]);

        // Validasi input (tambahkan emisi)
        $validated = $request->validate([
            'amount' => 'required|numeric|min:1',
            'emisi'  => 'required|numeric|min:0', // jumlah emisi (Kg CO2 atau satuan yang kamu pakai)
            'name'   => 'required|string|max:255',
            'email'  => 'required|email|max:255',
            'phone'  => 'required|string|max:20',
        ]);

        try {
            // SIMPAN DATA KE DATABASE SAAT PAYMENT DIBUAT (dengan emisi)
            $payment = Payment::create([
                'order_id' => $orderId,
                'amount' => $validated['amount'],
                'emisi' => $validated['emisi'],
                'customer_name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'transaction_status' => 'pending',
            ]);

            // Parameter transaksi untuk Midtrans
            $params = [
                'transaction_details' => [
                    'order_id' => $orderId,
                    'gross_amount' => (int) $validated['amount'],
                ],
                'customer_details' => [
                    'first_name' => $validated['name'],
                    'email' => $validated['email'],
                    'phone' => $validated['phone'],
                ],
                'item_details' => [
                    [
                        'id' => 'EMISI-' . $orderId,
                        'price' => (int) $validated['amount'],
                        'quantity' => 1,
                        // sertakan emisi di nama item agar jelas di laporan Midtrans (opsional)
                        'name' => 'Pembayaran Offset Emisi Karbon - ' . $validated['emisi'] . ' Kg CO₂',
                    ],
                ],
            ];

            Log::info('📤 Sending to Midtrans', [
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

            Log::info('📥 Midtrans Response', [
                'status_code' => $response->status(),
                'body' => $response->body(),
            ]);

            if (!$response->successful()) {
                $errorBody = $response->json();

                Log::error('❌ Midtrans API Error', [
                    'status' => $response->status(),
                    'error' => $errorBody,
                ]);

                // Jika perlu rollback / update DB bisa dilakukan di sini (opsional)
                return response()->json([
                    'success' => false,
                    'message' => 'Midtrans Error: ' . ($errorBody['error_messages'][0] ?? 'Unknown error'),
                ], 500);
            }

            $data = $response->json();
            $redirectUrl = $data['redirect_url'] ?? null;

            if (!$redirectUrl) {
                Log::error('❌ No redirect_url', ['response' => $data]);
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak mendapat URL pembayaran dari Midtrans',
                ], 500);
            }

            Log::info('✅ Payment Created Successfully', [
                'order_id' => $orderId,
                'redirect_url' => $redirectUrl,
                'token' => $data['token'] ?? null,
            ]);

            return response()->json([
                'success' => true,
                'order_id' => $orderId,
                'redirect_url' => $redirectUrl,
                'token' => $data['token'] ?? null,
                'message' => 'Transaksi berhasil dibuat',
            ], 200);

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('❌ Connection Error', ['message' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Koneksi ke Midtrans gagal: ' . $e->getMessage(),
            ], 500);

        } catch (\Exception $e) {
            Log::error('❌ Payment Error', [
                'message' => $e->getMessage(),
                'file' => method_exists($e,'getFile') ? $e->getFile() : null,
                'line' => method_exists($e,'getLine') ? $e->getLine() : null,
                'trace' => substr($e->getTraceAsString(), 0, 1000),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Midtrans callback (webhook)
     */
    public function callback(Request $request)
    {
        Log::info('📨 Midtrans Callback', $request->all());

        $serverKey = $this->serverKey;
        $orderId = $request->order_id;
        $statusCode = $request->status_code;
        $grossAmount = $request->gross_amount;
        $signatureKey = $request->signature_key;

        // Verify signature
        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($expectedSignature !== $signatureKey) {
            Log::warning('⚠️ Invalid Signature', [
                'order_id' => $orderId,
                'expected' => $expectedSignature,
                'received' => $signatureKey,
            ]);

            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $transactionStatus = $request->transaction_status;

        Log::info('✅ Callback Verified', [
            'order_id' => $orderId,
            'status' => $transactionStatus,
        ]);

        // UPDATE STATUS PAYMENT DI DATABASE
        $payment = Payment::where('order_id', $orderId)->first();
        if ($payment) {
            $payment->transaction_status = $transactionStatus;
            // juga simpan response raw (opsional), mis: $payment->raw_response = json_encode($request->all());
            $payment->save();
            Log::info('💾 Payment status updated in DB', ['order_id' => $orderId, 'status' => $transactionStatus]);
        } else {
            Log::warning('⚠️ Payment not found for order_id', ['order_id' => $orderId]);
        }

        return response()->json(['message' => 'Callback processed'], 200);
    }
	
	/**
     * Tambahkan method mypayments
     */
	public function myPayments(Request $request)
	{
		$user = $request->user();
		
		$payments = Payment::where('email', $user->Email_Masyarakat)
			->orderBy('created_at', 'desc')
			->get();
		
		return response()->json([
			'success' => true,
			'data' => $payments,
		]);
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

            Log::info('🔍 Checking Status', ['order_id' => $orderId, 'url' => $statusUrl]);

            $response = Http::timeout(30)
                ->withHeaders([
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'Authorization' => 'Basic ' . base64_encode($this->serverKey . ':'),
                ])
                ->withOptions(['verify' => false])
                ->get($statusUrl);

            if (!$response->successful()) {
                Log::error('❌ Check Status Failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Gagal cek status: ' . $response->body(),
                ], 500);
            }

            $data = $response->json();

            Log::info('✅ Status Retrieved', $data);

            return response()->json([
                'success' => true,
                'data' => $data,
            ], 200);

        } catch (\Exception $e) {
            Log::error('❌ Check Status Error', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }
}