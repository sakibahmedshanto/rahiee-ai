#!/bin/bash

# Deployment Script for Uniform Verification System
# Run this after installing Supabase CLI

set -e  # Exit on error

echo "🚀 Deploying Uniform Verification System..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found!${NC}"
    echo "Install it with: brew install supabase/tap/supabase"
    echo "Or: npm install -g supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}"
echo ""

# Login to Supabase
echo -e "${BLUE}Step 1: Login to Supabase${NC}"
echo "This will open your browser..."
supabase login

echo ""
echo -e "${BLUE}Step 2: Link to project${NC}"
supabase link --project-ref YOUR_SUPABASE_PROJECT_REF

echo ""
echo -e "${BLUE}Step 3: Set Google Cloud credentials${NC}"
echo "Reading credentials from: google vision api/YOUR_GOOGLE_PROJECT_ID-2bd981448940.json"

# Read the JSON file and set as secret
GOOGLE_CREDS=$(cat "google vision api/YOUR_GOOGLE_PROJECT_ID-2bd981448940.json" | tr -d '\n')
supabase secrets set GOOGLE_CLOUD_CREDENTIALS="${GOOGLE_CREDS}"

echo -e "${GREEN}✅ Google credentials set${NC}"
echo ""

echo -e "${BLUE}Step 4: Deploy Edge Function${NC}"
supabase functions deploy verify-uniform

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Function URL: https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/verify-uniform"
echo ""
echo "Next steps:"
echo "1. Test the function (see UNIFORM_VERIFICATION_DEPLOYMENT.md)"
echo "2. Implement Flutter camera screen"
echo "3. Integrate with check-in flow"
echo ""




