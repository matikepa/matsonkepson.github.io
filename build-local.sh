#!/usr/bin/env bash
set -e  # Exit on error

# echo 'cleanup ...'
# ./clean.sh

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed. Please install Python 3.x"
    exit 1
fi

# Add venv with error handling
echo "Creating Python virtual environment..."
python3 -m venv .venv || { echo "Failed to create virtual environment"; exit 1; }
source .venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Install dependencies
echo "Installing dependencies..."
python3 -m pip install --upgrade pip || { echo "Failed to upgrade pip"; exit 1; }
python3 -m pip install -r requirements.txt || { echo "Failed to install requirements"; exit 1; }

# Run pre-commit hooks
pre-commit run --all-files --verbose

#build with proper symlinks
echo 'building new one ...'
# hugo --environment prod
hugo serve

## misc
#missing customisations of my theme template
# echo "kepa.eu.org" >./public/CNAME

# resolved with ./assets/js/custom.js
# #inject google analytics tag
# GA_TAG_INDEX=$(cat ./static/gtag |awk '{print}' ORS='')

# sed -i "/<\/head>/i $GA_TAG_INDEX " ./public/index.html
# sed -i "/<\/head>/i $GA_TAG_INDEX " ./public/blog/index.html
# sed -i "/<\/head>/i $GA_TAG_INDEX " ./public/about/index.html

#serve to double check locally
# python3 -m http.server --directory ./public/
