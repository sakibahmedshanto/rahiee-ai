import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🕐 Starting hourly absence detection...");
    
    // Get current time and one hour ago
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    
    console.log(`Checking schedules that ended between ${oneHourAgo.toISOString()} and ${now.toISOString()}`);

    // Get Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    // Call the database function
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/mark_absent_for_time_range`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${supabaseServiceKey}`,
        "apikey": supabaseServiceKey,
      },
      body: JSON.stringify({
        p_start_time: oneHourAgo.toISOString(),
        p_end_time: now.toISOString(),
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Database call failed: ${response.status} - ${errorText}`);
    }

    const result = await response.json();
    
    console.log(`✅ Absence detection completed: ${result.absent_count} absences marked`);
    
    // Log the execution for monitoring
    await fetch(`${supabaseUrl}/rest/v1/system_logs`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${supabaseServiceKey}`,
        "apikey": supabaseServiceKey,
      },
      body: JSON.stringify({
        event_type: "hourly_absence_detection",
        event_data: {
          absent_count: result.absent_count,
          start_time: oneHourAgo.toISOString(),
          end_time: now.toISOString(),
          success: true,
        },
      }),
    });
    
    return new Response(
      JSON.stringify({
        success: true,
        message: "Hourly absence detection completed",
        absent_count: result.absent_count,
        time_range: {
          start: oneHourAgo.toISOString(),
          end: now.toISOString(),
        },
        processed_at: new Date().toISOString(),
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );

  } catch (error) {
    console.error("❌ Hourly absence detection failed:", error);
    
    // Log the error
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      
      await fetch(`${supabaseUrl}/rest/v1/system_logs`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${supabaseServiceKey}`,
          "apikey": supabaseServiceKey,
        },
        body: JSON.stringify({
          event_type: "hourly_absence_detection_error",
          event_data: {
            error: error.message,
            success: false,
          },
        }),
      });
    } catch (logError) {
      console.error("Failed to log error:", logError);
    }
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        processed_at: new Date().toISOString(),
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );
  }
});

