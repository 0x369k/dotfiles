#!/usr/bin/env bash

# Function to download and run the deploy script
run_deploy_script() {
    TEMP_SCRIPT="/tmp/deploy.sh"

    # Download the deploy script
    curl -fsSL https://github.com/0x369k/dotfiles/raw/main/.zsh/deploy.sh -o "$TEMP_SCRIPT"
    
    # Make the script executable
    chmod +x "$TEMP_SCRIPT"
    
    # Run the script
    "$TEMP_SCRIPT"
    
    # Remove the script after execution
    rm -f "$TEMP_SCRIPT"
}

# Execute the function
run_deploy_script
