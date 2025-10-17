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

// Generate JWT and get access token
async function getAccessToken(): Promise<string> {
  try {
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
      exp: now + 3600,
    };

    // Encode header and payload
    const encodedHeader = arrayBufferToBase64Url(
      new TextEncoder().encode(JSON.stringify(header))
    );
    const encodedPayload = arrayBufferToBase64Url(
      new TextEncoder().encode(JSON.stringify(payload))
    );

    const unsignedToken = `${encodedHeader}.${encodedPayload}`;

    // Import private key
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

    // Sign the token
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      new TextEncoder().encode(unsignedToken)
    );

    const encodedSignature = arrayBufferToBase64Url(signature);
    const jwt = `${unsignedToken}.${encodedSignature}`;

    // Exchange JWT for access token
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
      const error = await tokenResponse.text();
      throw new Error(`Failed to get access token: ${error}`);
    }

    const tokenData = await tokenResponse.json();
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
    const accessToken = await getAccessToken();
    
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
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    };

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      }
    );

    const resData = await res.json();
    
    if (res.status < 200 || res.status > 299) {
      console.error('FCM Error:', resData);
      return { 
        success: false, 
        error: resData.error?.message || 'FCM error'
      };
    }

    console.log('Notification sent successfully');
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

        // Send notification
        const result = await sendFirebaseNotification(
          userData.deviceToken,
          personalizedTitle,
          personalizedBody,
          dataPayload,
          requestData.imageUrl,
          requestData.priority || 'high'
        );

        return {
          userId: user.id,
          userName: user.full_name,
          success: result.success,
          error: result.error,
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
