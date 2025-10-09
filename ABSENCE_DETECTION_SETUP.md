# 🕐 Hourly Absence Detection System

## 📋 Overview
This system automatically detects employee absences every hour by checking schedules that ended in the last hour and creating attendance records for employees who didn't check in.

## 🏗️ Architecture

### Components:
1. **Supabase Edge Function** (`hourly-absence-detection`) - Main detection logic
2. **Database Functions** - Core absence detection and logging
3. **GitHub Actions** - Scheduled execution every hour
4. **System Logs** - Monitoring and debugging

## 🚀 Setup Instructions

### Step 1: Deploy Edge Function
```bash
# Deploy the Edge Function to Supabase
supabase functions deploy hourly-absence-detection
```

### Step 2: Set Up GitHub Actions
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add secret: `SUPABASE_ANON_KEY` with your Supabase anon key
4. The workflow will automatically run every hour

### Step 3: Test the System
```bash
# Make the test script executable
chmod +x test_absence_detection.sh

# Set your Supabase anon key
export SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Run the test
./test_absence_detection.sh
```

## 🔧 How It Works

### Every Hour:
1. **GitHub Actions** triggers at minute 0 of every hour
2. **Edge Function** is called with authentication
3. **Database Function** checks schedules that ended in the last hour
4. **Absence Records** are created for employees without attendance
5. **System Logs** record the execution results

### Detection Logic:
```sql
-- Finds schedules where:
-- 1. Schedule ended between (now - 1 hour) and now
-- 2. Employee is assigned to the schedule
-- 3. No attendance record exists for that employee/schedule
-- 4. Creates attendance record with status='absent'
```

## 📊 Monitoring

### Check Execution History:
```sql
SELECT get_absence_detection_history(10);
```

### Manual Trigger (for testing):
```sql
SELECT trigger_hourly_absence_detection();
```

### View System Logs:
```sql
SELECT * FROM system_logs 
WHERE event_type IN ('hourly_absence_detection', 'hourly_absence_detection_error')
ORDER BY created_at DESC 
LIMIT 10;
```

## 🎯 API Endpoints

### Edge Function:
- **URL**: `https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/hourly-absence-detection`
- **Method**: POST
- **Auth**: Bearer token (Supabase anon key)

### Database Functions:
- `mark_absent_for_time_range(start_time, end_time)` - Core detection
- `trigger_hourly_absence_detection()` - Manual trigger
- `get_absence_detection_history(limit)` - View logs

## 📈 Response Format

### Success Response:
```json
{
  "success": true,
  "message": "Hourly absence detection completed",
  "absent_count": 3,
  "time_range": {
    "start": "2025-10-08T09:00:00.000Z",
    "end": "2025-10-08T10:00:00.000Z"
  },
  "processed_at": "2025-10-08T10:00:00.000Z"
}
```

### Error Response:
```json
{
  "success": false,
  "error": "Database connection failed",
  "processed_at": "2025-10-08T10:00:00.000Z"
}
```

## 🔍 Troubleshooting

### Common Issues:

1. **Edge Function Not Deployed**
   - Run: `supabase functions deploy hourly-absence-detection`

2. **GitHub Actions Failing**
   - Check: Repository secrets are set correctly
   - Verify: SUPABASE_ANON_KEY is valid

3. **No Absences Detected**
   - Check: Are there schedules ending in the last hour?
   - Verify: Do employees have attendance records?

4. **Database Errors**
   - Check: System logs table exists
   - Verify: Functions have proper permissions

### Debug Commands:
```bash
# Test Edge Function directly
curl -X POST "https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/hourly-absence-detection" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"

# Check recent executions
curl -X POST "https://YOUR_SUPABASE_PROJECT_REF.supabase.co/rest/v1/rpc/get_absence_detection_history" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_limit": 5}'
```

## ⚙️ Configuration

### GitHub Actions Schedule:
- **Current**: Every hour at minute 0 (`0 * * * *`)
- **Customize**: Edit `.github/workflows/absence-detection.yml`

### Detection Window:
- **Current**: 1 hour lookback window
- **Customize**: Modify Edge Function time calculation

### Log Retention:
- **Current**: Unlimited (manual cleanup needed)
- **Recommendation**: Add cleanup job for old logs

## 🎉 Benefits

✅ **Fully Automated** - No manual intervention required  
✅ **Reliable** - GitHub Actions provides 99.9% uptime  
✅ **Scalable** - Supabase Edge Functions handle load  
✅ **Monitored** - Complete execution logging  
✅ **Testable** - Manual triggers for testing  
✅ **Cost-Effective** - GitHub Actions free tier sufficient  

## 📝 Next Steps

1. **Deploy Edge Function** to Supabase
2. **Set up GitHub Actions** with secrets
3. **Test the system** with manual triggers
4. **Monitor execution** via system logs
5. **Integrate with admin dashboard** for real-time updates

---

**Status**: ✅ Ready for deployment and testing!

