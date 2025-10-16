import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { verifySIWAToken } from '../_shared/auth.ts'
import { generateJWT, generateUserKey } from '../_shared/jwt.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const jwtSecret = Deno.env.get('JWT_SECRET')!
const bundleId = Deno.env.get('BUNDLE_ID') || 'com.neuraldraft.directorstudio'

interface ClaimRequest {
  siwa_id_token: string
  device_install_id: string
  app_build: string
  bundle_id: string
}

interface ClaimResponse {
  granted: boolean
  credits_delta: number
  auth_token?: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { siwa_id_token, device_install_id, app_build, bundle_id }: ClaimRequest = await req.json()

    // Validate required fields
    if (!siwa_id_token || !device_install_id || !app_build || !bundle_id) {
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          error: 'Missing required fields' 
        } as ClaimResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify bundle ID matches
    if (bundle_id !== bundleId) {
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          error: 'Invalid bundle ID' 
        } as ClaimResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify SIWA token
    const siwaPayload = await verifySIWAToken(siwa_id_token)
    if (!siwaPayload) {
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          error: 'Invalid SIWA token' 
        } as ClaimResponse),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Generate stable user key
    const userKey = generateUserKey(siwaPayload.iss, siwaPayload.sub, siwaPayload.aud, bundle_id)

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check if user already exists and has been granted first clip
    const { data: existingUser, error: fetchError } = await supabase
      .from('credit_ledger')
      .select('*')
      .eq('user_key', userKey)
      .single()

    if (fetchError && fetchError.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('Error fetching user:', fetchError)
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          error: 'Database error' 
        } as ClaimResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // If user exists and already granted, return existing status
    if (existingUser && existingUser.first_clip_granted) {
      const authToken = generateJWT(userKey, jwtSecret)
      
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          auth_token: authToken,
          error: 'First clip already granted' 
        } as ClaimResponse),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Grant first clip using database function
    const { data: grantResult, error: grantError } = await supabase
      .rpc('grant_first_clip', {
        p_user_key: userKey,
        p_device_id: device_install_id
      })

    if (grantError) {
      console.error('Error granting first clip:', grantError)
      return new Response(
        JSON.stringify({ 
          granted: false, 
          credits_delta: 0, 
          error: 'Failed to grant first clip' 
        } as ClaimResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Generate JWT token for future requests
    const authToken = generateJWT(userKey, jwtSecret)

    return new Response(
      JSON.stringify({ 
        granted: true, 
        credits_delta: 1, 
        auth_token: authToken 
      } as ClaimResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Claim first clip error:', error)
    return new Response(
      JSON.stringify({ 
        granted: false, 
        credits_delta: 0, 
        error: 'Internal server error' 
      } as ClaimResponse),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
