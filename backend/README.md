# DirectorStudio Backend

Backend services for DirectorStudio credit ledger and SIWA authentication using Supabase Edge Functions.

## Overview

This backend provides three main endpoints:
- `POST /claim-first-clip` - Grant 1 included clip credit per Apple account
- `POST /consume-credit` - Consume credits for video generation
- `POST /credit-topup` - Add credits after StoreKit purchase

## Architecture

- **Database**: PostgreSQL via Supabase with Row Level Security
- **Functions**: Deno Edge Functions for serverless execution
- **Auth**: Sign in with Apple (SIWA) JWT verification
- **Security**: JWT tokens with 15-minute expiry, rate limiting, CORS

## Setup

1. **Install Supabase CLI**:
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link to existing project**:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

4. **Set environment variables**:
   ```bash
   supabase secrets set JWT_SECRET=your-jwt-secret-key
   supabase secrets set BUNDLE_ID=com.neuraldraft.directorstudio
   ```

5. **Deploy database migrations**:
   ```bash
   supabase db push
   ```

6. **Deploy Edge Functions**:
   ```bash
   npm run deploy
   ```

## Environment Variables

- `JWT_SECRET` - Secret key for JWT signing (generate with `openssl rand -base64 32`)
- `BUNDLE_ID` - iOS app bundle identifier (default: com.neuraldraft.directorstudio)
- `SUPABASE_URL` - Your Supabase project URL (auto-set)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (auto-set)

## API Endpoints

### POST /claim-first-clip

Claims the included clip credit for a new Apple account.

**Request**:
```json
{
  "siwa_id_token": "eyJ...",
  "device_install_id": "uuid-v4",
  "app_build": "1.0.0",
  "bundle_id": "com.neuraldraft.directorstudio"
}
```

**Response**:
```json
{
  "granted": true,
  "credits_delta": 1,
  "auth_token": "eyJ..."
}
```

### POST /consume-credit

Consumes credits for video generation.

**Request**:
```json
{
  "auth_token": "eyJ...",
  "amount": 1
}
```

**Response**:
```json
{
  "success": true,
  "remaining": 4
}
```

### POST /credit-topup

Adds credits after StoreKit purchase.

**Request**:
```json
{
  "auth_token": "eyJ...",
  "product_id": "com.neuraldraft.directorstudio.credits_20",
  "transaction_id": "2000000123456789",
  "signed_transaction": "base64-encoded-transaction"
}
```

**Response**:
```json
{
  "success": true,
  "new_balance": 21
}
```

## Database Schema

### credit_ledger
- `user_key` (TEXT) - Stable identifier derived from SIWA token
- `credits` (INTEGER) - Current credit balance
- `first_clip_granted` (BOOLEAN) - Whether included clip was granted
- `device_ids` (TEXT[]) - Array of device UUIDs

### credit_transactions
- `user_key` (TEXT) - User identifier
- `transaction_type` (TEXT) - 'claim', 'consume', or 'topup'
- `amount` (INTEGER) - Credit amount (positive/negative)
- `transaction_id` (TEXT) - StoreKit transaction ID
- `signed_transaction` (TEXT) - Full transaction data

### auth_tokens
- `user_key` (TEXT) - User identifier
- `token_hash` (TEXT) - Hash of JWT for lookup
- `expires_at` (TIMESTAMP) - Token expiry

## Security Features

- **SIWA Verification**: Validates Apple ID tokens against Apple's public keys
- **JWT Tokens**: Short-lived tokens (15 minutes) with HMAC-SHA256 signing
- **Rate Limiting**: 30 requests/minute per user, 100 requests/minute per IP
- **CORS**: Configured for iOS app origin
- **Row Level Security**: Database access restricted to service role
- **Nonce Validation**: Prevents replay attacks in SIWA flow

## Development

1. **Start local development**:
   ```bash
   npm run dev
   ```

2. **View function logs**:
   ```bash
   npm run logs
   ```

3. **Test functions locally**:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/claim-first-clip \
     -H "Content-Type: application/json" \
     -d '{"siwa_id_token":"test","device_install_id":"test","app_build":"1.0.0","bundle_id":"com.neuraldraft.directorstudio"}'
   ```

## Production Deployment

1. **Deploy to Supabase**:
   ```bash
   npm run deploy
   ```

2. **Monitor logs**:
   ```bash
   supabase functions logs --follow
   ```

3. **Update secrets**:
   ```bash
   supabase secrets set JWT_SECRET=new-secret
   ```

## Error Handling

All endpoints return consistent error responses:
```json
{
  "success": false,
  "error": "Error message",
  "remaining": 0
}
```

Common error codes:
- `400` - Bad Request (missing/invalid parameters)
- `401` - Unauthorized (invalid/expired token)
- `409` - Conflict (duplicate transaction)
- `500` - Internal Server Error

## Monitoring

- Function execution logs available in Supabase dashboard
- Database queries logged for debugging
- Error tracking via console.error statements
- Performance metrics via Supabase analytics
