import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req: Request) => {
  try {
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
    
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // Debug environment variables
    const envVars = {
      FIREBASE_PROJECT_ID: Deno.env.get('FIREBASE_PROJECT_ID'),
      FIREBASE_CLIENT_EMAIL: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      FIREBASE_PRIVATE_KEY: Deno.env.get('FIREBASE_PRIVATE_KEY') ? 'SET' : 'NOT_SET',
      SUPABASE_URL: Deno.env.get('SUPABASE_URL'),
      SUPABASE_SERVICE_ROLE_KEY: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ? 'SET' : 'NOT_SET',
    };
    
    console.log('Environment variables:', envVars);
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Environment variables debug',
      envVars: envVars,
    }), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
    
  } catch (error) {
    console.error('Debug function error:', error);
    
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      details: error.message,
    }), {
      status: 500,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});
