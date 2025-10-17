import { encode, decode } from "https://deno.land/std@0.168.0/encoding/base64.ts"

interface JWTPayload {
  sub: string
  iat: number
  exp: number
  iss: string
  aud: string
}

interface SIWAPayload {
  iss: string
  sub: string
  aud: string
  iat: number
  exp: number
  nonce?: string
  email?: string
  email_verified?: boolean
}

// Generate JWT token for authenticated requests
export function generateJWT(userKey: string, secret: string): string {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  }

  const now = Math.floor(Date.now() / 1000)
  const payload: JWTPayload = {
    sub: userKey,
    iat: now,
    exp: now + (15 * 60), // 15 minutes expiry
    iss: 'directorstudio-backend',
    aud: 'directorstudio-app'
  }

  const encodedHeader = encode(JSON.stringify(header))
  const encodedPayload = encode(JSON.stringify(payload))
  const signature = encode(await sign(`${encodedHeader}.${encodedPayload}`, secret))

  return `${encodedHeader}.${encodedPayload}.${signature}`
}

// Verify JWT token
export function verifyJWT(token: string, secret: string): JWTPayload | null {
  try {
    const parts = token.split('.')
    if (parts.length !== 3) {
      return null
    }

    const [encodedHeader, encodedPayload, encodedSignature] = parts
    
    // Decode payload
    const payload = JSON.parse(new TextDecoder().decode(decode(encodedPayload))) as JWTPayload
    
    // Check expiry with 2 minute clock skew tolerance
    const now = Math.floor(Date.now() / 1000)
    if (payload.exp < (now - 120)) { // 2 minutes tolerance
      return null
    }

    // Verify signature
    const expectedSignature = encode(sign(`${encodedHeader}.${encodedPayload}`, secret))
    if (encodedSignature !== expectedSignature) {
      return null
    }

    return payload
  } catch (error) {
    console.error('JWT verification error:', error)
    return null
  }
}

// Generate stable user key from SIWA payload
export function generateUserKey(iss: string, sub: string, aud: string, bundleId: string): string {
  const data = `${iss}|${sub}|${aud}|${bundleId}`
  return encode(await hash(data))
}

// Simple HMAC-SHA256 implementation for JWT signing
async function sign(data: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data))
  return new TextDecoder().decode(encode(new Uint8Array(signature)))
}

// Simple SHA-256 hash implementation
async function hash(data: string): Promise<string> {
  const hashBuffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(data))
  return new TextDecoder().decode(encode(new Uint8Array(hashBuffer)))
}
