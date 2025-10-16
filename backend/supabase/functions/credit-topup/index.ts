import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { verifyJWT } from '../_shared/jwt.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const jwtSecret = Deno.env.get('JWT_SECRET')!

// Product ID to credit mapping
const PRODUCT_CREDITS: Record<string, number> = {
  'com.neuraldraft.directorstudio.credits_5': 5,
  'com.neuraldraft.directorstudio.credits_20': 20,
  'com.neuraldraft.directorstudio.credits_100': 100,
}

interface TopupRequest {
  auth_token: string
  product_id: string
  transaction_id: string
  signed_transaction: string
}

interface TopupResponse {
  success: boolean
  new_balance: number
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { auth_token, product_id, transaction_id, signed_transaction }: TopupRequest = await req.json()

    // Validate required fields
    if (!auth_token || !product_id || !transaction_id || !signed_transaction) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          new_balance: 0, 
          error: 'Missing required fields' 
        } as TopupResponse),
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
          new_balance: 0, 
          error: 'Invalid or expired token' 
        } as TopupResponse),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const userKey = payload.sub

    // Validate product ID and get credit amount
    const creditAmount = PRODUCT_CREDITS[product_id]
    if (!creditAmount) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          new_balance: 0, 
          error: 'Invalid product ID' 
        } as TopupResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check if transaction already exists (prevent duplicate topups)
    const { data: existingTransaction, error: checkError } = await supabase
      .from('credit_transactions')
      .select('id')
      .eq('transaction_id', transaction_id)
      .eq('transaction_type', 'topup')
      .single()

    if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('Error checking existing transaction:', checkError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          new_balance: 0, 
          error: 'Database error' 
        } as TopupResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (existingTransaction) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          new_balance: 0, 
          error: 'Transaction already processed' 
        } as TopupResponse),
        { 
          status: 409, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Top up credits using database function
    const { data: topupResult, error: topupError } = await supabase
      .rpc('topup_credits', {
        p_user_key: userKey,
        p_amount: creditAmount,
        p_product_id: product_id,
        p_transaction_id: transaction_id,
        p_signed_transaction: signed_transaction
      })

    if (topupError) {
      console.error('Error topping up credits:', topupError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          new_balance: 0, 
          error: 'Failed to top up credits' 
        } as TopupResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        new_balance: topupResult 
      } as TopupResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Credit topup error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        new_balance: 0, 
        error: 'Internal server error' 
      } as TopupResponse),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
