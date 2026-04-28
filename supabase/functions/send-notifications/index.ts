import { createClient } from 'npm:@supabase/supabase-js@2'
import serviceAccount from './YOUR_GOOGLE_PROJECT_ID-firebase-adminsdk-fbsvc-1a539ac37f.json' with { type: 'json' }

interface NotificationRequest {
  userIds: string[];
  type: 'schedule_assignment' | 'schedule_update' | 'schedule_cancellation' | 'attendance_reminder' | 'general' | 'custom';
  title: string;
  body: string;
  data?: Record<string, any>;
  imageUrl?: string;
  scheduleData?: {
    scheduleId?: string;
    startTime?: string;
    endTime?: string;
    location?: string;
    department?: string;
  };
  priority?: 'high' | 'normal' | 'low';
  actionType?: string;
  expiresInDays?: number;
  saveToDatabase?: boolean; // Default: true
}

interface UserNotificationData {
  userId: string;
  deviceToken: string;
  fullName: string;
  email: string;
  department: string;
}

// Initialize Supabase client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

// Helper to convert ArrayBuffer to base64url
function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Generate JWT and get access token using latest Web Crypto API
async function getAccessToken(): Promise<string> {
  try {
    console.log('Generating JWT for Firebase access token...');
    
    const header = {
      alg: 'RS256',
      typ: 'JWT',
    };

    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600, // Token expires in 1 hour
    };

    console.log('JWT Payload:', payload);

    // Encode header and payload using base64url
    const encodedHeader = arrayBufferToBase64Url(
      new TextEncoder().encode(JSON.stringify(header))
    );
    const encodedPayload = arrayBufferToBase64Url(
      new TextEncoder().encode(JSON.stringify(payload))
    );

    const unsignedToken = `${encodedHeader}.${encodedPayload}`;
    console.log('Unsigned JWT created');

    // Process private key
    const pemHeader = '-----BEGIN PRIVATE KEY-----';
    const pemFooter = '-----END PRIVATE KEY-----';
    const pemContents = serviceAccount.private_key
      .replace(pemHeader, '')
      .replace(pemFooter, '')
      .replace(/\\n/g, '')
      .replace(/\s/g, '');

    const binaryDer = atob(pemContents);
    const binaryDerArray = new Uint8Array(binaryDer.length);
    for (let i = 0; i < binaryDer.length; i++) {
      binaryDerArray[i] = binaryDer.charCodeAt(i);
    }

    console.log('Importing private key...');
    const key = await crypto.subtle.importKey(
      'pkcs8',
      binaryDerArray,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    );

    console.log('Signing JWT...');
    // Sign the token
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      new TextEncoder().encode(unsignedToken)
    );

    const encodedSignature = arrayBufferToBase64Url(signature);
    const jwt = `${unsignedToken}.${encodedSignature}`;
    console.log('JWT generated successfully');

    // Exchange JWT for access token
    console.log('Exchanging JWT for access token...');
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error('Token exchange failed:', errorText);
      throw new Error(`Failed to get access token: ${tokenResponse.status} - ${errorText}`);
    }

    const tokenData = await tokenResponse.json();
    console.log('Access token obtained successfully');
    return tokenData.access_token;
  } catch (error) {
    console.error('Error getting access token:', error);
    throw error;
  }
}

// Send notification using Firebase Cloud Messaging API v1
async function sendFirebaseNotification(
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
  imageUrl?: string,
  priority: string = 'high'
): Promise<{ success: boolean; error?: string }> {
  try {
    console.log(`Attempting to send notification to token: ${deviceToken.substring(0, 20)}...`);
    console.log(`Title: ${title}, Body: ${body}`);
    
    const accessToken = await getAccessToken();
    console.log('Access token obtained successfully');
    
    const message = {
      message: {
        token: deviceToken,
        notification: {
          title: title,
          body: body,
          image: imageUrl,
        },
        data: data ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ) : {},
        android: {
          priority: priority === 'high' ? 'high' : 'normal',
          notification: {
            channel_id: 'rahiee_notifications',
            sound: 'default',
            icon: 'ic_notification',
            color: '#FF6B35',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            tag: 'rahiee_notification',
            visibility: 'public',
            title: title,
            body: body,
          },
        },
        apns: {
          headers: {
            'apns-priority': priority === 'high' ? '10' : '5',
            'apns-expiration': String(Math.floor(Date.now() / 1000) + 86400), // 24 hours
            'apns-collapse-id': 'rahiee_notification',
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
              category: 'SCHEDULE_NOTIFICATION',
              'mutable-content': 1,
              'content-available': 1,
            },
          },
        },
        webpush: {
          headers: {
            'TTL': '86400',
          },
          notification: {
            title: title,
            body: body,
            icon: '/icon-192x192.png',
            badge: '/badge-72x72.png',
            requireInteraction: true,
            actions: [
              {
                action: 'view',
                title: 'View',
              },
              {
                action: 'dismiss',
                title: 'Dismiss',
              },
            ],
          },
        },
        fcm_options: {
          analytics_label: 'rahiee_notification',
        },
      },
    };

    console.log('Sending FCM request...');
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      }
    );

    const resData = await res.json();
    console.log('FCM Response Status:', res.status);
    console.log('FCM Response Data:', resData);
    
    if (!res.ok) {
      console.error('FCM Error Response:', resData);
      const errorMessage = resData.error?.message || resData.message || `HTTP ${res.status}`;
      return { 
        success: false, 
        error: `FCM error: ${errorMessage}`
      };
    }

    console.log('Notification sent successfully via FCM v1 API');
    return { success: true };

  } catch (error) {
    console.error('Send notification error:', error);
    return { 
      success: false, 
      error: error.message 
    };
  }
}

// Personalize content with user data
function personalizeContent(
  content: string,
  userData: UserNotificationData,
  scheduleData?: any
): string {
  let personalized = content;
  
  // User data placeholders
  const firstName = userData.fullName.split(' ')[0];
  personalized = personalized.replace(/{firstName}/g, firstName);
  personalized = personalized.replace(/{userName}/g, userData.fullName);
  personalized = personalized.replace(/{email}/g, userData.email);
  personalized = personalized.replace(/{department}/g, userData.department || 'your department');
  
  // Schedule data placeholders
  if (scheduleData) {
    personalized = personalized.replace(/{scheduleId}/g, scheduleData.scheduleId || '');
    personalized = personalized.replace(/{startTime}/g, scheduleData.startTime || '');
    personalized = personalized.replace(/{endTime}/g, scheduleData.endTime || '');
    personalized = personalized.replace(/{location}/g, scheduleData.location || '');
  }
  
  return personalized;
}

// Save notification to database
async function saveNotificationToDatabase(
  userId: string,
  title: string,
  body: string,
  type: string,
  imageUrl?: string,
  priority?: string,
  actionType?: string,
  actionData?: Record<string, any>,
  scheduleData?: any,
  batchId?: string,
  expiresInDays?: number
): Promise<{ success: boolean; notificationId?: string; error?: string }> {
  try {
    const notificationData = {
      user_id: userId,
      title,
      body,
      image_url: imageUrl,
      type,
      priority: priority || 'normal',
      action_type: actionType,
      action_data: actionData ? actionData : null,
      schedule_id: scheduleData?.scheduleId,
      schedule_data: scheduleData ? scheduleData : null,
      batch_id: batchId,
      status: 'sent',
      is_read: false,
      sent_at: new Date().toISOString(),
      expires_at: expiresInDays 
        ? new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000).toISOString()
        : null,
    };

    const { data, error } = await supabase
      .from('notifications')
      .insert(notificationData)
      .select('id')
      .single();

    if (error) {
      console.error('Failed to save notification to database:', error);
      return { success: false, error: error.message };
    }

    return { success: true, notificationId: data.id };
  } catch (error) {
    console.error('Error saving notification:', error);
    return { success: false, error: error.message };
  }
}

// Notification templates
const TEMPLATES = {
  schedule_assignment: {
    title: 'New Schedule Assignment',
    body: 'Hey {firstName}! You have been assigned to a new schedule.',
  },
  schedule_update: {
    title: 'Schedule Updated',
    body: 'Hey {firstName}! Your schedule has been updated.',
  },
  schedule_cancellation: {
    title: 'Schedule Cancelled',
    body: 'Hey {firstName}! A schedule has been cancelled.',
  },
  attendance_reminder: {
    title: 'Attendance Reminder',
    body: 'Hey {firstName}! Don\'t forget to mark your attendance.',
  },
  general: {
    title: 'Notification',
    body: 'Hey {firstName}! You have a new notification.',
  },
  custom: {
    title: '',
    body: '',
  },
};

// Main handler
Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  try {
    const requestData: NotificationRequest = await req.json();
    
    // Validate required fields
    if (!requestData.userIds || !Array.isArray(requestData.userIds) || requestData.userIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'userIds array is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
      );
    }

    if (!requestData.type) {
      return new Response(
        JSON.stringify({ error: 'type is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
      );
    }

    // Get template or use custom values
    const template = TEMPLATES[requestData.type] || TEMPLATES.general;
    const title = requestData.title || template.title;
    const body = requestData.body || template.body;

    // Fetch user data from database
    console.log('Fetching user data for:', requestData.userIds);
    const { data: users, error: userError } = await supabase
      .from('my_users')
      .select('id, full_name, email, department, user_device_token')
      .in('id', requestData.userIds);

    if (userError) {
      console.error('Database error:', userError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user data', details: userError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
      );
    }

    if (!users || users.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true,
          sentCount: 0,
          failedCount: 0,
          message: 'No users found'
        }),
        { status: 200, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
      );
    }

    // Filter users with valid device tokens
    const validUsers = users.filter(u => u.user_device_token);
    
    if (validUsers.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true,
          sentCount: 0,
          failedCount: users.length,
          message: 'No users with valid device tokens'
        }),
        { status: 200, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
      );
    }

    console.log(`Processing notifications for ${validUsers.length} users`);

    // Generate batch ID for this notification batch
    const batchId = crypto.randomUUID();
    const saveToDb = requestData.saveToDatabase !== false; // Default: true

    // Send notifications to all users
    const results = await Promise.all(
      validUsers.map(async (user) => {
        const userData: UserNotificationData = {
          userId: user.id,
          deviceToken: user.user_device_token!,
          fullName: user.full_name,
          email: user.email,
          department: user.department || '',
        };

        // Personalize content
        const personalizedTitle = personalizeContent(title, userData, requestData.scheduleData);
        const personalizedBody = personalizeContent(body, userData, requestData.scheduleData);

        // Prepare data payload
        const dataPayload = {
          type: requestData.type,
          ...(requestData.data || {}),
          ...(requestData.scheduleData || {}),
        };

        // Send notification via FCM
        const result = await sendFirebaseNotification(
          userData.deviceToken,
          personalizedTitle,
          personalizedBody,
          dataPayload,
          requestData.imageUrl,
          requestData.priority || 'high'
        );

        // Save to database
        let notificationId: string | undefined;
        if (saveToDb) {
          const dbResult = await saveNotificationToDatabase(
            user.id,
            personalizedTitle,
            personalizedBody,
            requestData.type,
            requestData.imageUrl,
            requestData.priority,
            requestData.actionType,
            dataPayload,
            requestData.scheduleData,
            batchId,
            requestData.expiresInDays
          );
          notificationId = dbResult.notificationId;
          
          if (!dbResult.success) {
            console.warn(`Failed to save notification to DB for user ${user.id}:`, dbResult.error);
          }
        }

        return {
          userId: user.id,
          userName: user.full_name,
          success: result.success,
          error: result.error,
          notificationId,
        };
      })
    );

    // Aggregate results
    const sentCount = results.filter(r => r.success).length;
    const failedCount = results.filter(r => !r.success).length;
    const errors = results
      .filter(r => !r.success)
      .map(r => `${r.userName}: ${r.error}`);

    console.log(`Sent: ${sentCount}, Failed: ${failedCount}`);

    return new Response(
      JSON.stringify({
        success: true,
        sentCount,
        failedCount,
        errors,
        batchId,
        processedUsers: results,
      }),
      {
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
      }
    );

  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        details: error.message 
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      }
    );
  }
});
