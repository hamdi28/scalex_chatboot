#!/bin/bash

# ScaleX Chatbot - Setup and Run Script
echo "🚀 ScaleX AI Chatbot - Setup & Run Script"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo -e "\n${YELLOW}Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed. Please install Flutter first.${NC}"
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found${NC}"
flutter --version

# Clean previous builds
echo -e "\n${YELLOW}Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"

# Get dependencies
echo -e "\n${YELLOW}Getting dependencies...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to get dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Generate code (for Hive adapters)
echo -e "\n${YELLOW}Generating code...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Code generation had issues, but continuing...${NC}"
fi
echo -e "${GREEN}✓ Code generation complete${NC}"

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "\n${YELLOW}Warning: .env file not found!${NC}"
    echo "Creating .env template..."
    cat > .env << EOF
API_BASE_URL=http://localhost:3000/api
OPENAI_API_KEY=your-openai-key-here
ANTHROPIC_API_KEY=your-anthropic-key-here
GROK_API_KEY=your-grok-key-here
EOF
    echo -e "${GREEN}✓ .env file created. Please add your API keys!${NC}"
fi

# Run the app
echo -e "\n${GREEN}Starting the app...${NC}"
flutter run

echo -e "\n${GREEN}✅ Done!${NC}"