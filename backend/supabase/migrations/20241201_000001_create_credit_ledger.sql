-- Create credit ledger table for DirectorStudio
-- Enforces 1 included clip per Apple account across devices

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create credit ledger table
CREATE TABLE credit_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_key TEXT NOT NULL UNIQUE, -- sha256(iss|sub|aud|bundle_id) from SIWA
    credits INTEGER NOT NULL DEFAULT 0,
    first_clip_granted BOOLEAN NOT NULL DEFAULT FALSE,
    first_clip_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    granted_at TIMESTAMP WITH TIME ZONE,
    device_ids TEXT[] DEFAULT '{}', -- Array of device UUIDs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create credit transactions table for audit trail
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_key TEXT NOT NULL,
    transaction_type TEXT NOT NULL, -- 'claim', 'consume', 'topup'
    amount INTEGER NOT NULL, -- Positive for credits added, negative for consumed
    product_id TEXT, -- For topup transactions
    transaction_id TEXT, -- StoreKit transaction ID
    signed_transaction TEXT, -- Full StoreKit transaction data
    metadata JSONB DEFAULT '{}', -- Additional context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create auth tokens table for JWT management
CREATE TABLE auth_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_key TEXT NOT NULL,
    token_hash TEXT NOT NULL, -- Hash of the JWT for lookup
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_credit_ledger_user_key ON credit_ledger(user_key);
CREATE INDEX idx_credit_transactions_user_key ON credit_transactions(user_key);
CREATE INDEX idx_credit_transactions_created_at ON credit_transactions(created_at);
CREATE INDEX idx_auth_tokens_user_key ON auth_tokens(user_key);
CREATE INDEX idx_auth_tokens_expires_at ON auth_tokens(expires_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at trigger to credit_ledger
CREATE TRIGGER update_credit_ledger_updated_at 
    BEFORE UPDATE ON credit_ledger 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to clean up expired tokens
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM auth_tokens WHERE expires_at < NOW();
END;
$$ language 'plpgsql';

-- Create function to get user credits
CREATE OR REPLACE FUNCTION get_user_credits(p_user_key TEXT)
RETURNS INTEGER AS $$
DECLARE
    user_credits INTEGER;
BEGIN
    SELECT credits INTO user_credits 
    FROM credit_ledger 
    WHERE user_key = p_user_key;
    
    RETURN COALESCE(user_credits, 0);
END;
$$ language 'plpgsql';

-- Create function to consume credits atomically
CREATE OR REPLACE FUNCTION consume_credits(
    p_user_key TEXT,
    p_amount INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    current_credits INTEGER;
BEGIN
    -- Get current credits
    SELECT credits INTO current_credits 
    FROM credit_ledger 
    WHERE user_key = p_user_key;
    
    -- Check if user has enough credits
    IF current_credits IS NULL OR current_credits < p_amount THEN
        RETURN FALSE;
    END IF;
    
    -- Consume credits
    UPDATE credit_ledger 
    SET credits = credits - p_amount,
        updated_at = NOW()
    WHERE user_key = p_user_key;
    
    -- Log transaction
    INSERT INTO credit_transactions (user_key, transaction_type, amount, metadata)
    VALUES (p_user_key, 'consume', -p_amount, jsonb_build_object('consumed_at', NOW()));
    
    RETURN TRUE;
END;
$$ language 'plpgsql';

-- Create function to grant first clip
CREATE OR REPLACE FUNCTION grant_first_clip(
    p_user_key TEXT,
    p_device_id TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    existing_record RECORD;
BEGIN
    -- Check if user already exists
    SELECT * INTO existing_record 
    FROM credit_ledger 
    WHERE user_key = p_user_key;
    
    IF existing_record IS NOT NULL THEN
        -- User exists, check if already granted
        IF existing_record.first_clip_granted THEN
            RETURN FALSE; -- Already granted
        END IF;
        
        -- Grant the first clip
        UPDATE credit_ledger 
        SET credits = credits + 1,
            first_clip_granted = TRUE,
            granted_at = NOW(),
            device_ids = array_append(device_ids, p_device_id),
            updated_at = NOW()
        WHERE user_key = p_user_key;
        
        -- Log transaction
        INSERT INTO credit_transactions (user_key, transaction_type, amount, metadata)
        VALUES (p_user_key, 'claim', 1, jsonb_build_object('device_id', p_device_id, 'granted_at', NOW()));
        
        RETURN TRUE;
    ELSE
        -- New user, create record with first clip
        INSERT INTO credit_ledger (user_key, credits, first_clip_granted, granted_at, device_ids)
        VALUES (p_user_key, 1, TRUE, NOW(), ARRAY[p_device_id]);
        
        -- Log transaction
        INSERT INTO credit_transactions (user_key, transaction_type, amount, metadata)
        VALUES (p_user_key, 'claim', 1, jsonb_build_object('device_id', p_device_id, 'granted_at', NOW()));
        
        RETURN TRUE;
    END IF;
END;
$$ language 'plpgsql';

-- Create function to top up credits
CREATE OR REPLACE FUNCTION topup_credits(
    p_user_key TEXT,
    p_amount INTEGER,
    p_product_id TEXT,
    p_transaction_id TEXT,
    p_signed_transaction TEXT
)
RETURNS INTEGER AS $$
DECLARE
    new_balance INTEGER;
BEGIN
    -- Add credits
    UPDATE credit_ledger 
    SET credits = credits + p_amount,
        updated_at = NOW()
    WHERE user_key = p_user_key;
    
    -- Get new balance
    SELECT credits INTO new_balance 
    FROM credit_ledger 
    WHERE user_key = p_user_key;
    
    -- Log transaction
    INSERT INTO credit_transactions (user_key, transaction_type, amount, product_id, transaction_id, signed_transaction, metadata)
    VALUES (p_user_key, 'topup', p_amount, p_product_id, p_transaction_id, p_signed_transaction, jsonb_build_object('topped_up_at', NOW()));
    
    RETURN new_balance;
END;
$$ language 'plpgsql';

-- Enable Row Level Security
ALTER TABLE credit_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies (restrictive - only service role can access)
CREATE POLICY "Service role can manage credit_ledger" ON credit_ledger
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage credit_transactions" ON credit_transactions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage auth_tokens" ON auth_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions to service role
GRANT ALL ON credit_ledger TO service_role;
GRANT ALL ON credit_transactions TO service_role;
GRANT ALL ON auth_tokens TO service_role;
