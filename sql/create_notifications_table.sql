-- =====================================================
-- Notifications Table - Complete Implementation
-- =====================================================
-- This table stores all notifications sent to users
-- Follows industry best practices for notification management

-- Drop existing table if needed (for fresh setup)
-- DROP TABLE IF EXISTS public.notifications CASCADE;

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User reference
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification content
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    
    -- Notification metadata
    type VARCHAR(50) NOT NULL DEFAULT 'general',
    category VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'normal',
    
    -- Action data (JSON for flexibility)
    action_type VARCHAR(50),
    action_data JSONB,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- Delivery tracking
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    failed_reason TEXT,
    
    -- Grouping and batching
    batch_id UUID,
    group_key VARCHAR(100),
    
    -- Schedule related (if applicable)
    schedule_id VARCHAR(100),
    schedule_data JSONB,
    
    -- Expiry and cleanup
    expires_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_batch_id ON public.notifications(batch_id);
CREATE INDEX IF NOT EXISTS idx_notifications_schedule_id ON public.notifications(schedule_id);
CREATE INDEX IF NOT EXISTS idx_notifications_expires_at ON public.notifications(expires_at) WHERE expires_at IS NOT NULL;

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

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
    ON public.notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read, etc.)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
    ON public.notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Service role can insert notifications
DROP POLICY IF EXISTS "Service role can insert notifications" ON public.notifications;
CREATE POLICY "Service role can insert notifications"
    ON public.notifications
    FOR INSERT
    WITH CHECK (true);

-- Service role can manage all notifications
DROP POLICY IF EXISTS "Service role can manage notifications" ON public.notifications;
CREATE POLICY "Service role can manage notifications"
    ON public.notifications
    FOR ALL
    USING (auth.role() = 'service_role');

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.notifications
    SET 
        is_read = TRUE,
        read_at = NOW(),
        status = 'read'
    WHERE 
        id = notification_id 
        AND user_id = auth.uid()
        AND is_read = FALSE;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read()
RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE public.notifications
    SET 
        is_read = TRUE,
        read_at = NOW(),
        status = 'read'
    WHERE 
        user_id = auth.uid()
        AND is_read = FALSE;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count()
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO unread_count
    FROM public.notifications
    WHERE 
        user_id = auth.uid()
        AND is_read = FALSE
        AND deleted_at IS NULL
        AND (expires_at IS NULL OR expires_at > NOW());
    
    RETURN unread_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to soft delete notification
CREATE OR REPLACE FUNCTION delete_notification(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.notifications
    SET deleted_at = NOW()
    WHERE 
        id = notification_id 
        AND user_id = auth.uid();
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete old notifications (cleanup job)
CREATE OR REPLACE FUNCTION cleanup_old_notifications(days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notifications
    WHERE 
        created_at < NOW() - (days_old || ' days')::INTERVAL
        OR (expires_at IS NOT NULL AND expires_at < NOW());
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE public.notifications IS 'Stores all push notifications sent to users with complete tracking';
COMMENT ON COLUMN public.notifications.id IS 'Unique notification identifier';
COMMENT ON COLUMN public.notifications.user_id IS 'User who received the notification';
COMMENT ON COLUMN public.notifications.title IS 'Notification title';
COMMENT ON COLUMN public.notifications.body IS 'Notification message body';
COMMENT ON COLUMN public.notifications.type IS 'Type of notification (schedule_assignment, general, etc.)';
COMMENT ON COLUMN public.notifications.status IS 'Current status: sent, delivered, read, failed';
COMMENT ON COLUMN public.notifications.is_read IS 'Whether user has read the notification';
COMMENT ON COLUMN public.notifications.batch_id IS 'Groups notifications sent in the same batch';
COMMENT ON COLUMN public.notifications.action_data IS 'JSON data for notification actions';
COMMENT ON COLUMN public.notifications.expires_at IS 'When the notification should expire';

-- Grant permissions
GRANT ALL ON public.notifications TO service_role;
GRANT SELECT, UPDATE ON public.notifications TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Notifications table created successfully with all indexes, triggers, and RLS policies!';
END $$;


