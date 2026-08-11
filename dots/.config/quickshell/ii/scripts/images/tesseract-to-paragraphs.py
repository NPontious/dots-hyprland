#!/usr/bin/env python3
import sys
import csv
import json

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tesseract-to-paragraphs.py <tsv_file>")
        sys.exit(1)

    tsv_file = sys.argv[1]
    paragraphs = {}
    
    with open(tsv_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        start_idx = 0
        for i, line in enumerate(lines):
            if line.startswith('level\tpage_num'):
                start_idx = i
                break
        
        reader = csv.DictReader(lines[start_idx:], delimiter='\t')
        for row in reader:
            try:
                level = int(row['level'])
                par_num = int(row['par_num'])
                block_num = int(row['block_num'])
                page_num = int(row['page_num'])
            except ValueError:
                continue

            par_id = f"{page_num}_{block_num}_{par_num}"

            if level == 3: # Paragraph
                paragraphs[par_id] = {
                    'boundingBox': {
                        'vertices': [
                            {'x': int(row['left']), 'y': int(row['top'])},
                            {'x': int(row['left']) + int(row['width']), 'y': int(row['top'])},
                            {'x': int(row['left']) + int(row['width']), 'y': int(row['top']) + int(row['height'])},
                            {'x': int(row['left']), 'y': int(row['top']) + int(row['height'])}
                        ]
                    },
                    'text_parts': []
                }
            elif level == 5: # Word
                if par_id in paragraphs:
                    text = row['text']
                    if text.strip():
                        paragraphs[par_id]['text_parts'].append(text)

    result = []
    for p in paragraphs.values():
        if p['text_parts']:
            p['text'] = " ".join(p['text_parts'])
            del p['text_parts']
            result.append(p)
            
    print(json.dumps(result))

if __name__ == '__main__':
    main()
