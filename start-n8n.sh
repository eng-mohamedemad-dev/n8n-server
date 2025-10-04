#!/bin/bash

# 1️⃣ وقف الحاويات القديمة
docker compose down

# 2️⃣ شغّل ngrok أول حاجة لوحده
echo "Starting ngrok first..."
docker compose up -d ngrok
sleep 5

# 3️⃣ جيب الـ URL من ngrok
echo "Getting ngrok URL..."
for i in {1..20}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    
    if [ ! -z "$NGROK_URL" ] && [ "$NGROK_URL" != "null" ]; then
        echo "✓ ngrok URL detected: $NGROK_URL"
        break
    fi
    
    echo "Attempt $i/20: Waiting for ngrok..."
    sleep 2
done

if [ -z "$NGROK_URL" ] || [ "$NGROK_URL" = "null" ]; then
    echo "❌ Error: Could not get ngrok URL"
    exit 1
fi

# 4️⃣ حدّث ملف .env
cat > .env << EOF
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=Your-User
N8N_BASIC_AUTH_PASSWORD=Admin@123

# ngrok
NGROK_AUTHTOKEN=2pYVU92XCCjTcxLx7D5lAc12kzo_2ZtobC8KidHfu1Cwzkxgr

# Dynamic URLs
N8N_EDITOR_BASE_URL=$NGROK_URL
WEBHOOK_URL=$NGROK_URL/
EOF

echo "✓ Updated .env with N8N_EDITOR_BASE_URL=$NGROK_URL"

# 5️⃣ دلوقتي شغّل n8n بالـ URL الصحيح
echo "Starting n8n with correct URL..."
docker compose up -d n8n

# 6️⃣ استنى شوية n8n يخلص startup
sleep 8

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DONE!"
echo ""
echo "🌐 Access n8n at:"
echo "   $NGROK_URL"
echo ""
echo "🔑 Add this to Google Cloud Console:"
echo "   $NGROK_URL/rest/oauth2-credential/callback"
echo ""
echo "📝 Credentials:"
echo "   Username: Your-User"
echo "   Password: Admin@123"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
