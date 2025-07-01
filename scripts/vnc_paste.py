#!/usr/bin/env python3
"""
VNC Paste Script - Types clipboard content character by character
Useful for VNC consoles where paste doesn't work properly
"""

import subprocess
import time
import sys
import argparse

def get_clipboard():
    """Get clipboard content from macOS"""
    try:
        result = subprocess.run(['pbpaste'], capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError:
        print("Error: Could not read clipboard")
        sys.exit(1)

def type_text(text, delay=0.05):
    """Type text character by character using AppleScript"""
    print(f"Starting to type {len(text)} characters...")
    print("Switch to your VNC window now! Starting in 3 seconds...")
    time.sleep(3)
    
    for i, char in enumerate(text):
        if char == '\n':
            # Handle newlines
            applescript = 'tell application "System Events" to key code 36'
        elif char == '\t':
            # Handle tabs
            applescript = 'tell application "System Events" to key code 48'
        elif char == '.':
            # Handle period specifically
            applescript = 'tell application "System Events" to key code 47'
        elif char in '"\\':
            # Escape quotes and backslashes for AppleScript
            escaped_char = char.replace('\\', '\\\\').replace('"', '\\"')
            applescript = f'tell application "System Events" to keystroke "{escaped_char}"'
        else:
            # Regular characters
            applescript = f'tell application "System Events" to keystroke "{char}"'
        
        try:
            subprocess.run(['osascript', '-e', applescript], check=True)
        except subprocess.CalledProcessError:
            print(f"Error typing character: {char}")
            continue
            
        # Progress indicator
        if (i + 1) % 50 == 0:
            print(f"Progress: {i + 1}/{len(text)} characters")
            
        time.sleep(delay)
    
    print(f"Finished typing {len(text)} characters!")

def main():
    parser = argparse.ArgumentParser(description='Type clipboard content into VNC console')
    parser.add_argument('--delay', '-d', type=float, default=0.05, 
                       help='Delay between keystrokes in seconds (default: 0.05)')
    parser.add_argument('--preview', '-p', action='store_true',
                       help='Preview clipboard content without typing')
    
    args = parser.parse_args()
    
    # Get clipboard content
    clipboard_text = get_clipboard()
    
    if not clipboard_text.strip():
        print("Clipboard is empty!")
        sys.exit(1)
    
    print(f"Clipboard contains {len(clipboard_text)} characters")
    
    if args.preview:
        print("Clipboard content:")
        print("-" * 40)
        print(clipboard_text)
        print("-" * 40)
        return
    
    # Confirm before typing
    response = input("Type this into VNC console? (y/N): ")
    if response.lower() != 'y':
        print("Cancelled.")
        return
    
    # Type the text
    type_text(clipboard_text, args.delay)

if __name__ == "__main__":
    main()