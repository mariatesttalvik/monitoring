#!/bin/bash

# Find all markdown files
find docs -name "*.md" -type f | while read file; do
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Process the file
  awk '
  BEGIN { in_mermaid = 0; content = ""; }
  
  /^```mermaid/ { 
    in_mermaid = 1; 
    content = "<div class=\"mermaid\">\n";
    next; 
  }
  
  /^```/ && in_mermaid { 
    in_mermaid = 0; 
    content = content "</div>";
    print content;
    content = "";
    next; 
  }
  
  in_mermaid { content = content $0 "\n"; next; }
  
  { print; }
  ' "$file" > "$temp_file"
  
  # Replace the original file with the processed one
  mv "$temp_file" "$file"
  
  echo "Processed $file"
done
