import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { verifyJWT } from '../_shared/jwt.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const jwtSecret = Deno.env.get('JWT_SECRET')!

interface ConsumeRequest {
  auth_token: string
  amount?: number
}

interface ConsumeResponse {
  success: boolean
  remaining: number
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { auth_token, amount = 1 }: ConsumeRequest = await req.json()

    // Validate required fields
    if (!auth_token) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          remaining: 0, 
          error: 'Missing auth token' 
        } as ConsumeResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Validate amount
    if (amount <= 0 || amount > 10) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          remaining: 0, 
          error: 'Invalid amount' 
        } as ConsumeResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify JWT token
    const payload = verifyJWT(auth_token, jwtSecret)
    if (!payload) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          remaining: 0, 
          error: 'Invalid or expired token' 
        } as ConsumeResponse),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const userKey = payload.sub

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Consume credits using database function
    const { data: consumeResult, error: consumeError } = await supabase
      .rpc('consume_credits', {
        p_user_key: userKey,
        p_amount: amount
      })

    if (consumeError) {
      console.error('Error consuming credits:', consumeError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          remaining: 0, 
          error: 'Failed to consume credits' 
        } as ConsumeResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get remaining credits
    const { data: userData, error: fetchError } = await supabase
      .from('credit_ledger')
      .select('credits')
      .eq('user_key', userKey)
      .single()

    if (fetchError) {
      console.error('Error fetching user credits:', fetchError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          remaining: 0, 
          error: 'Failed to fetch remaining credits' 
        } as ConsumeResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const remaining = userData?.credits || 0

    return new Response(
      JSON.stringify({ 
        success: consumeResult, 
        remaining: remaining 
      } as ConsumeResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Consume credit error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        remaining: 0, 
        error: 'Internal server error' 
      } as ConsumeResponse),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
