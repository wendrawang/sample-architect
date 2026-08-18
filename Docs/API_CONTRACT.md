# Example API Contract

Live service memakai `API_BASE_URL` dari `Info.plist`. Mock aktif secara default agar project langsung bisa dijalankan.

## Login

`POST /v1/auth/login`

```json
{
  "username": "wendra",
  "password": "secret123"
}
```

```json
{
  "access_token": "token",
  "display_name": "Wendra"
}
```

## Dashboard inquiry

`GET /v1/dashboard/summary`

```json
{
  "customer_name": "Wendra",
  "account_number": "123456789012",
  "available_balance": 24850000,
  "transactions": [
    {
      "id": "trx-1",
      "title": "Transfer masuk",
      "subtitle": "Hari ini, 09:42",
      "amount": 1500000
    }
  ]
}
```

## Transfer

`POST /v1/transfers`

```json
{
  "destination_account": "9876543210",
  "amount": 100000
}
```

```json
{
  "reference_number": "TRF-123456",
  "amount": 100000
}
```

Semua non-2xx response sebaiknya menyediakan `{ "message": "..." }`. Tambahkan interceptor token, certificate pinning/mTLS, dan mapping error code sesuai standar backend perusahaan di composition layer; jangan letakkan credential di package feature.

