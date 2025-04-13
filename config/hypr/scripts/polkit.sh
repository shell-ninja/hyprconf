#!/bin/bash

# Polkit possible paths files to check
polkit=(
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  "/usr/lib/polkit-kde-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-mate-authentication-agent-1"
  "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

executed=false  # Flag to track if a file has been executed

# Loop through the list of files
for file in "${polkit[@]}"; do
  if [ -e "$file" ]; then
    exec "$file"  
    executed=true
    break
  fi
done
