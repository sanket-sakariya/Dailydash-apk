-- ============================================
-- Supabase PostgreSQL Schema for DailyDash
-- Run this in your Supabase SQL Editor
-- ============================================

-- Create the expenses table
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount DECIMAL(12, 2) NOT NULL,
  date_time TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  payment_mode TEXT NOT NULL,
  is_income BOOLEAN DEFAULT false,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_last_modified ON public.expenses(last_modified);
CREATE INDEX IF NOT EXISTS idx_expenses_is_deleted ON public.expenses(is_deleted);
CREATE INDEX IF NOT EXISTS idx_expenses_date_time ON public.expenses(date_time);

-- Create function to auto-update last_modified timestamp
CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_modified = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update last_modified on UPDATE
DROP TRIGGER IF EXISTS expenses_last_modified ON public.expenses;
CREATE TRIGGER expenses_last_modified
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified();

-- Enable Row Level Security
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete own expenses" ON public.expenses;

-- Create RLS policies
-- Users can only SELECT their own expenses
CREATE POLICY "Users can view own expenses"
  ON public.expenses
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only INSERT expenses for themselves
CREATE POLICY "Users can insert own expenses"
  ON public.expenses
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only UPDATE their own expenses
CREATE POLICY "Users can update own expenses"
  ON public.expenses
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can only DELETE their own expenses
CREATE POLICY "Users can delete own expenses"
  ON public.expenses
  FOR DELETE
  USING (auth.uid() = user_id);

-- Grant access to authenticated users
GRANT ALL ON public.expenses TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
