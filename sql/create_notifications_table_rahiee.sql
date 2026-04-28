-- Create notifications table for Rahiee.AI
-- Run this in Supabase SQL Editor

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    type VARCHAR(50) NOT NULL DEFAULT 'general',
    category VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'normal',
    action_type VARCHAR(50),
    action_data JSONB,
    status VARCHAR(20) DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    failed_reason TEXT,
    batch_id UUID,
    group_key VARCHAR(100),
    schedule_id VARCHAR(100),
    schedule_data JSONB,
    expires_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.my_users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_batch_id ON public.notifications(batch_id);
CREATE INDEX IF NOT EXISTS idx_notifications_schedule_id ON public.notifications(schedule_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notifications_updated_at_trigger ON public.notifications;
CREATE TRIGGER notifications_updated_at_trigger
    BEFORE UPDATE ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_notifications_updated_at();

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
    ON public.notifications FOR UPDATE
    USING (user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid()))
    WITH CHECK (user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Service role can insert notifications" ON public.notifications;
CREATE POLICY "Service role can insert notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role can manage notifications" ON public.notifications;
CREATE POLICY "Service role can manage notifications"
    ON public.notifications FOR ALL
    USING (auth.role() = 'service_role');

-- Helper functions
CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, read_at = NOW(), status = 'read'
    WHERE id = notification_id 
    AND user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid())
    AND is_read = FALSE;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_all_notifications_as_read()
RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, read_at = NOW(), status = 'read'
    WHERE user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid())
    AND is_read = FALSE;
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_unread_notification_count()
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO unread_count
    FROM public.notifications
    WHERE user_id IN (SELECT id FROM public.my_users WHERE id = auth.uid())
    AND is_read = FALSE AND deleted_at IS NULL
    AND (expires_at IS NULL OR expires_at > NOW());
    RETURN unread_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to get user notifications (bypasses schema cache)
CREATE OR REPLACE FUNCTION public.get_user_notifications(
  p_user_id UUID,
  p_limit_count INTEGER DEFAULT 20,
  p_offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  title VARCHAR(255),
  body TEXT,
  image_url TEXT,
  type VARCHAR(50),
  category VARCHAR(50),
  priority VARCHAR(20),
  action_type VARCHAR(50),
  action_data JSONB,
  status VARCHAR(20),
  is_read BOOLEAN,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  failed_reason TEXT,
  batch_id UUID,
  group_key VARCHAR(100),
  schedule_id VARCHAR(100),
  schedule_data JSONB,
  expires_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.user_id,
    n.title,
    n.body,
    n.image_url,
    n.type,
    n.category,
    n.priority,
    n.action_type,
    n.action_data,
    n.status,
    n.is_read,
    n.read_at,
    n.sent_at,
    n.delivered_at,
    n.failed_reason,
    n.batch_id,
    n.group_key,
    n.schedule_id,
    n.schedule_data,
    n.expires_at,
    n.deleted_at,
    n.created_at,
    n.updated_at
  FROM public.notifications n
  WHERE n.user_id = p_user_id
    AND n.deleted_at IS NULL
    AND (n.expires_at IS NULL OR n.expires_at > NOW())
  ORDER BY n.created_at DESC
  LIMIT p_limit_count
  OFFSET p_offset_count;
END;
$$;
