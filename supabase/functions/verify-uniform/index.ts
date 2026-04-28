// Supabase Edge Function: Uniform Verification
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate";

interface UniformVerificationRequest {
  image_base64: string;
  user_id: string;
  schedule_id?: string;
}

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { image_base64, user_id, schedule_id }: UniformVerificationRequest = await req.json();

    if (!image_base64 || !user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Missing required fields: image_base64, user_id",
          wearing_uniform: false,
          confidence: 0,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Processing request for user: ${user_id}`);

    // Get Google Cloud credentials
    const credsStr = Deno.env.get("GOOGLE_CLOUD_CREDENTIALS");
    if (!credsStr) {
      throw new Error("GOOGLE_CLOUD_CREDENTIALS not configured");
    }
    
    const creds = JSON.parse(credsStr);

    // Create JWT header and payload
    const jwtHeader = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = btoa(JSON.stringify({
      iss: creds.client_email,
      scope: "https://www.googleapis.com/auth/cloud-vision",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }));

    // Extract and import private key
    const pemKey = creds.private_key;
    const pemContents = pemKey
      .replace("-----BEGIN PRIVATE KEY-----", "")
      .replace("-----END PRIVATE KEY-----", "")
      .replace(/\s+/g, "");
    
    const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
    
    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      binaryKey.buffer,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    );

    // Sign JWT
    const signatureInput = `${jwtHeader}.${jwtPayload}`;
    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      new TextEncoder().encode(signatureInput)
    );
    
    const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
    
    const jwt = `${signatureInput}.${signatureB64}`;

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    if (!tokenResponse.ok) {
      throw new Error(`Token exchange failed: ${await tokenResponse.text()}`);
    }

    const tokenData = await tokenResponse.json();
    
    if (!tokenData.access_token) {
      throw new Error("No access token received");
    }

    console.log("✅ Access token obtained");

    // Clean image data (remove data URL prefix if present)
    const cleanImage = image_base64.replace(/^data:image\/(png|jpg|jpeg);base64,/, "");

    // Call Google Cloud Vision API
    const visionResponse = await fetch(VISION_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${tokenData.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        requests: [{
          image: { content: cleanImage },
          features: [
            { type: "LABEL_DETECTION", maxResults: 20 },
            { type: "IMAGE_PROPERTIES", maxResults: 5 },
          ],
        }],
      }),
    });

    if (!visionResponse.ok) {
      const errorText = await visionResponse.text();
      throw new Error(`Vision API failed: ${errorText}`);
    }

    const visionData = await visionResponse.json();
    
    if (visionData.responses?.[0]?.error) {
      throw new Error(`Vision API error: ${visionData.responses[0].error.message}`);
    }

    const labels = visionData.responses[0]?.labelAnnotations || [];
    console.log(`Detected ${labels.length} labels`);

    // Analyze labels for uniform detection
    const uniformKeywords = [
      "uniform", "clothing", "shirt", "formal", "professional", 
      "suit", "collar", "dress", "blazer", "workwear", "attire"
    ];
    
    const casualKeywords = ["casual", "t-shirt", "tank", "shorts"];

    let uniformScore = 0;
    let casualScore = 0;
    const matchedLabels: string[] = [];

    // Check if person is detected
    const personDetected = labels.some(l => 
      ["person", "face", "people", "man", "woman", "human"].some(keyword => 
        l.description.toLowerCase().includes(keyword)
      )
    );

    if (!personDetected) {
      return new Response(
        JSON.stringify({
          success: true,
          wearing_uniform: false,
          confidence: 0,
          message: "No person detected in image. Please retake the photo.",
          suggestions: ["Show yourself clearly", "Ensure good lighting", "Face the camera"],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Score labels
    for (const label of labels) {
      const desc = label.description.toLowerCase();
      const score = label.score * 100;

      if (uniformKeywords.some(keyword => desc.includes(keyword))) {
        uniformScore += score;
        matchedLabels.push(`${label.description} (${score.toFixed(0)}%)`);
      }
      
      if (casualKeywords.some(keyword => desc.includes(keyword))) {
        casualScore += score;
      }
    }

    // Calculate confidence
    const netScore = uniformScore - casualScore;
    const confidence = Math.min(Math.max(netScore / 3, 0), 100);
    const wearing_uniform = confidence > 50;

    let message = "";
    const suggestions: string[] = [];

    if (wearing_uniform) {
      message = matchedLabels.length > 0 
        ? `✅ Uniform verified! Detected: ${matchedLabels.slice(0, 2).join(", ")}`
        : "✅ Uniform verified!";
    } else if (confidence > 30) {
      message = "⚠️ Uniform unclear. Retake or continue anyway.";
      suggestions.push("Ensure uniform is worn", "Better lighting may help");
    } else {
      message = "❌ No uniform detected.";
      suggestions.push("Please wear uniform", "Or continue without uniform");
    }

    console.log(`Result: ${wearing_uniform ? "PASS" : "FAIL"} (${confidence.toFixed(0)}%)`);

    return new Response(
      JSON.stringify({
        success: true,
        wearing_uniform,
        confidence: Math.round(confidence),
        message,
        suggestions: suggestions.length > 0 ? suggestions : undefined,
        detection_data: {
          labels: labels.slice(0, 10).map(l => ({
            name: l.description,
            confidence: Math.round(l.score * 100),
          })),
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("❌ Error:", error.message);
    return new Response(
      JSON.stringify({
        success: false,
        message: error.message || "Internal server error",
        wearing_uniform: false,
        confidence: 0,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});