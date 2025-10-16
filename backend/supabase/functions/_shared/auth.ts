import { decode } from "https://deno.land/std@0.168.0/encoding/base64.ts"

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

interface AppleJWKS {
  keys: Array<{
    kty: string
    kid: string
    use: string
    alg: string
    n: string
    e: string
  }>
}

// Cache for Apple's JWKS
let jwksCache: AppleJWKS | null = null
let jwksCacheExpiry = 0

// Fetch Apple's JWKS (JSON Web Key Set)
async function fetchAppleJWKS(): Promise<AppleJWKS | null> {
  const now = Date.now()
  
  // Return cached JWKS if still valid (cache for 1 hour)
  if (jwksCache && now < jwksCacheExpiry) {
    return jwksCache
  }

  try {
    const response = await fetch('https://appleid.apple.com/auth/keys')
    if (!response.ok) {
      throw new Error(`Failed to fetch JWKS: ${response.status}`)
    }
    
    jwksCache = await response.json() as AppleJWKS
    jwksCacheExpiry = now + (60 * 60 * 1000) // 1 hour
    return jwksCache
  } catch (error) {
    console.error('Error fetching Apple JWKS:', error)
    return null
  }
}

// Verify SIWA token signature using Apple's public keys
async function verifySIWASignature(token: string): Promise<boolean> {
  try {
    const parts = token.split('.')
    if (parts.length !== 3) {
      return false
    }

    const [headerEncoded, payloadEncoded, signatureEncoded] = parts
    
    // Decode header to get key ID
    const header = JSON.parse(new TextDecoder().decode(decode(headerEncoded)))
    const keyId = header.kid
    
    if (!keyId) {
      return false
    }

    // Get Apple's JWKS
    const jwks = await fetchAppleJWKS()
    if (!jwks) {
      return false
    }

    // Find the matching key
    const key = jwks.keys.find(k => k.kid === keyId)
    if (!key) {
      return false
    }

    // Import the public key
    const publicKey = await crypto.subtle.importKey(
      'jwk',
      {
        kty: key.kty,
        kid: key.kid,
        use: key.use,
        alg: key.alg,
        n: key.n,
        e: key.e
      },
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256'
      },
      false,
      ['verify']
    )

    // Verify the signature
    const data = new TextEncoder().encode(`${headerEncoded}.${payloadEncoded}`)
    const signature = decode(signatureEncoded)
    
    return await crypto.subtle.verify(
      'RSASSA-PKCS1-v1_5',
      publicKey,
      signature,
      data
    )
  } catch (error) {
    console.error('SIWA signature verification error:', error)
    return false
  }
}

// Verify SIWA token
export async function verifySIWAToken(token: string): Promise<SIWAPayload | null> {
  try {
    // First verify the signature
    const isValidSignature = await verifySIWASignature(token)
    if (!isValidSignature) {
      return null
    }

    // Decode the payload
    const parts = token.split('.')
    if (parts.length !== 3) {
      return null
    }

    const payloadEncoded = parts[1]
    const payload = JSON.parse(new TextDecoder().decode(decode(payloadEncoded))) as SIWAPayload

    // Verify issuer
    if (payload.iss !== 'https://appleid.apple.com') {
      return null
    }

    // Verify audience (bundle ID)
    const bundleId = Deno.env.get('BUNDLE_ID') || 'com.neuraldraft.directorstudio'
    if (payload.aud !== bundleId) {
      return null
    }

    // Check expiry with 2 minute clock skew tolerance
    const now = Math.floor(Date.now() / 1000)
    if (payload.exp < (now - 120)) { // 2 minutes tolerance
      return null
    }

    // Check issued at time (not too far in the future)
    if (payload.iat > (now + 60)) { // 1 minute tolerance
      return null
    }

    return payload
  } catch (error) {
    console.error('SIWA token verification error:', error)
    return null
  }
}
