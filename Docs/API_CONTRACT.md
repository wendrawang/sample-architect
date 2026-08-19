# Example API Contract

Live service memakai `API_BASE_URL` dari `Info.plist`. Mock aktif secara default agar project langsung bisa dijalankan.

## Splash bootstrap inquiry

`GET /v1/app/bootstrap`

```json
{
  "next_route": "preLogin",
  "is_maintenance": false,
  "force_update": false,
  "is_authenticated": false,
  "message": null
}
```

Endpoint ini memakai network pipeline yang sama, termasuk mTLS bila diaktifkan. Jika backend mengharuskan signature sebelum login, ubah policy endpoint dari `.ifAvailable` menjadi `.required` setelah pre-auth signer dikonfigurasi.

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
  "refresh_token": "optional-refresh-token",
  "expires_in": 3600,
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

Semua non-2xx response sebaiknya menyediakan `{ "code": "...", "message": "..." }`. Bearer interceptor, mTLS, header/signature adapter, dan error mapping sudah berada di `CoreNetwork`; konfigurasi concrete secret/credential tetap dilakukan di composition layer. Jangan letakkan credential di package feature.

Gunakan `AUTH_FAILURE_HEADER`/`AUTH_FAILURE_VALUE` bila backend dapat menandai 401 yang benar-benar berarti access-token expiry. Dengan marker tersebut, 401 business authorization tidak ikut memicu token refresh.
