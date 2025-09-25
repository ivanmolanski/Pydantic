#!/bin/bash

# Platform Migration Script for Pydantic MCP Server
# Easily switch between hosting platforms or set up new deployments

set -e

echo "🌐 Pydantic MCP Server Platform Migration"
echo "========================================"

API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# Function to display platform menu
show_platforms() {
    echo ""
    echo "Available hosting platforms:"
    echo "1) Railway (Current - Already working)"
    echo "2) Render.com (Recommended backup)"
    echo "3) Vercel (Serverless - Fast)"
    echo "4) Fly.io (Docker-based)"
    echo "5) Test current Railway deployment"
    echo "6) Generate GitHub Copilot config for any URL"
    echo "0) Exit"
    echo ""
}

# Function to test deployment
test_deployment() {
    local url=$1
    local platform=$2
    
    echo "🧪 Testing $platform deployment at: $url"
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -f -s "$url/health" > /dev/null; then
        echo "✅ Health endpoint: OK"
    else
        echo "❌ Health endpoint: FAILED"
        return 1
    fi
    
    # Test MCP endpoint
    echo "Testing MCP endpoint..."
    MCP_RESPONSE=$(curl -s -X POST "$url/mcp" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}')
    
    if echo "$MCP_RESPONSE" | grep -q "tools"; then
        echo "✅ MCP endpoint: OK"
        echo "✅ $platform deployment is working!"
        return 0
    else
        echo "❌ MCP endpoint: FAILED"
        echo "Response: $MCP_RESPONSE"
        return 1
    fi
}

# Function to generate GitHub Copilot config
generate_copilot_config() {
    local url=$1
    local name=${2:-"pydanticAgent"}
    
    cat << EOF
{
  "mcpServers": {
    "$name": {
      "type": "http",
      "url": "$url/mcp",
      "headers": {
        "Authorization": "Bearer $API_KEY"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
EOF
}

# Railway setup
setup_railway() {
    echo "🚂 Setting up Railway deployment..."
    
    if ! command -v railway &> /dev/null; then
        echo "Installing Railway CLI..."
        curl -fsSL https://railway.app/install.sh | sh
        export PATH="$HOME/.railway/bin:$PATH"
    fi
    
    echo "1. Make sure you're logged in: railway login"
    echo "2. Link to existing project or create new: railway link / railway init"
    echo "3. Run the railway setup script:"
    echo "   ./railway_setup.sh"
    echo ""
    echo "Current Railway deployment: https://pydantic-mcp-server-production.up.railway.app"
}

# Render setup
setup_render() {
    echo "🎨 Setting up Render deployment..."
    
    echo "Step-by-step setup:"
    echo "1. Go to https://render.com and sign up/login"
    echo "2. Click 'New' -> 'Web Service'"
    echo "3. Connect your GitHub account and select this repository"
    echo "4. Configure the service:"
    echo "   - Name: pydantic-mcp-server"
    echo "   - Environment: Python 3"
    echo "   - Build Command: pip install -e ."
    echo "   - Start Command: python -c \"from src.mcp_local_rag.simple_http_server import run_server; run_server()\""
    echo "5. Set environment variables:"
    echo "   - MCP_API_KEY: $API_KEY"
    echo "   - PORT: 10000"
    echo "   - HOST: 0.0.0.0"
    echo "   - PYTHONPATH: /opt/render/project/src"
    echo "6. Click 'Create Web Service'"
    echo ""
    echo "✅ render.yaml file is already configured for easy deployment!"
}

# Vercel setup
setup_vercel() {
    echo "▲ Setting up Vercel deployment..."
    
    if ! command -v vercel &> /dev/null; then
        echo "Installing Vercel CLI..."
        npm i -g vercel
    fi
    
    echo "Step-by-step setup:"
    echo "1. Run: vercel login"
    echo "2. Run: vercel --prod"
    echo "3. Follow the prompts to deploy"
    echo ""
    echo "✅ vercel.json file is already configured!"
    echo "✅ Serverless handler is ready at src/mcp_local_rag/vercel_handler.py"
    
    read -p "Deploy to Vercel now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deploying to Vercel..."
        vercel --prod
    fi
}

# Fly.io setup
setup_flyio() {
    echo "🪶 Setting up Fly.io deployment..."
    
    if ! command -v flyctl &> /dev/null; then
        echo "Installing Fly CLI..."
        curl -L https://fly.io/install.sh | sh
        export PATH="$HOME/.fly/bin:$PATH"
    fi
    
    echo "Step-by-step setup:"
    echo "1. Run: flyctl auth login"
    echo "2. Run: flyctl apps create pydantic-mcp-server"
    echo "3. Run: flyctl deploy"
    echo ""
    echo "✅ fly.toml file is already configured!"
    
    read -p "Deploy to Fly.io now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deploying to Fly.io..."
        if flyctl auth whoami &> /dev/null; then
            flyctl deploy
        else
            echo "Please login first: flyctl auth login"
        fi
    fi
}

# Main menu loop
while true; do
    show_platforms
    read -p "Select platform (0-6): " choice
    
    case $choice in
        1)
            setup_railway
            ;;
        2)
            setup_render
            ;;
        3)
            setup_vercel
            ;;
        4)
            setup_flyio
            ;;
        5)
            echo "🧪 Testing current Railway deployment..."
            if test_deployment "https://pydantic-mcp-server-production.up.railway.app" "Railway"; then
                echo ""
                echo "📋 GitHub Copilot Configuration:"
                generate_copilot_config "https://pydantic-mcp-server-production.up.railway.app"
            fi
            ;;
        6)
            echo ""
            read -p "Enter your deployment URL (without /mcp): " url
            read -p "Enter server name (default: pydanticAgent): " server_name
            server_name=${server_name:-"pydanticAgent"}
            
            echo ""
            echo "📋 GitHub Copilot Configuration:"
            generate_copilot_config "$url" "$server_name"
            
            echo ""
            read -p "Test this deployment? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                platform_name=$(echo "$url" | sed -E 's/https?:\/\///' | cut -d'.' -f1)
                test_deployment "$url" "$platform_name"
            fi
            ;;
        0)
            echo "👋 Goodbye!"
            break
            ;;
        *)
            echo "❌ Invalid option. Please select 0-6."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done

echo ""
echo "📚 Additional Resources:"
echo "- Detailed hosting guide: ALTERNATIVE_HOSTING.md"
echo "- GitHub Copilot setup: GITHUB_COPILOT_SETUP.md"
echo "- Railway debugging: ./railway_debug.sh"
echo "- Test all endpoints: ./validate_setup.sh"