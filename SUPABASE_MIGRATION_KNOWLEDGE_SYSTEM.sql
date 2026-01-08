-- Migration: Add Knowledge System Tables and Columns
-- Run this in your Supabase SQL Editor

-- PART 1: Create user_entities table
CREATE TABLE IF NOT EXISTS user_entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  confidence FLOAT DEFAULT 0.5,
  mention_count INT DEFAULT 1,
  confirmed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security for user_entities
ALTER TABLE user_entities ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own entities
CREATE POLICY "Users can view own entities"
  ON user_entities FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own entities
CREATE POLICY "Users can insert own entities"
  ON user_entities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own entities
CREATE POLICY "Users can update own entities"
  ON user_entities FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own entities
CREATE POLICY "Users can delete own entities"
  ON user_entities FOR DELETE
  USING (auth.uid() = user_id);

-- PART 2: Add domain and keywords columns to ideas table
ALTER TABLE ideas 
  ADD COLUMN IF NOT EXISTS domain TEXT,
  ADD COLUMN IF NOT EXISTS keywords TEXT[];

-- Create index on domain for faster queries
CREATE INDEX IF NOT EXISTS idx_ideas_domain ON ideas(domain);

-- Create GIN index on keywords for array searches
CREATE INDEX IF NOT EXISTS idx_ideas_keywords ON ideas USING GIN(keywords);

-- PART 3: Update idea_links table to support keyword-based linking
-- (Assuming idea_links already exists from previous setup)
-- The similarity column already exists and will be calculated based on keywords

-- Optional: Add comment for documentation
COMMENT ON COLUMN ideas.domain IS 'Top-level domain: Business, Tech, Creative, or Personal';
COMMENT ON COLUMN ideas.keywords IS 'Array of 2-3 auto-assigned keywords for linking';
COMMENT ON TABLE user_entities IS 'Extracted entities (people, products, companies, etc.) from transcripts';



