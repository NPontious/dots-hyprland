#!/usr/bin/env python3
import sys
import json
import subprocess

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 translate-local.py <target_lang> <json_file>")
        sys.exit(1)

    target_lang = sys.argv[1]
    input_file = sys.argv[2]
    
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    texts = data.get('contents', [])
    if not texts:
        print(json.dumps({"translations": []}))
        sys.exit(0)
        
    translations = []
    for text in texts:
        try:
            res = subprocess.run(
                ['trans', '-b', '-t', target_lang, text], 
                capture_output=True, text=True, check=True
            )
            translated = res.stdout.strip()
            # If trans fails silently or returns empty string, fallback to original
            if not translated:
                translated = text
            translations.append({"translatedText": translated})
        except subprocess.CalledProcessError as e:
            translations.append({"translatedText": text})
            
    print(json.dumps({"translations": translations}))

if __name__ == '__main__':
    main()
