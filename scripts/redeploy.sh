#!/bin/bash
# Quick redeploy script

echo "🔄 Redeploying Edge Function with fixes..."
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai
supabase functions deploy verify-uniform
echo ""
echo "✅ Redeployment complete!"
echo ""
echo "Test it with: ./test_uniform_function.sh"




