#!/usr/bin/env python3
import sys
import argparse

def parse_markdown_list(file_path):
    """
    Parses markdown lists into tuples of (indent_level, text).
    Assumes spaces for indentation, 2 or 4 spaces per level.
    Returns list of (level, text).
    """
    items = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.lstrip()
            if stripped.startswith(('-', '*')):
                # Count leading spaces (indentation)
                indent = len(line) - len(stripped)
                # Calculate level assuming 2 spaces per indent level
                level = indent // 2 + 1
                # Extract the list item text after the dash/asterisk and space
                text = stripped[1:].strip()
                items.append((level, text))
    return items

def print_tree(items, max_level):
    """
    Prints the markdown list tree up to max_level depth.
    max_level can be int or '*'
    """
    for level, text in items:
        if max_level == '*' or level <= max_level:
            indent = '  ' * (level - 1)
            print(f"{indent}- {text}")

def main():
    parser = argparse.ArgumentParser(description="Markdown list tree viewer")
    parser.add_argument("-L", required=True, help="List depth: integer or *")
    parser.add_argument("file", help="Markdown file path")
    args = parser.parse_args()

    # Parse max level
    if args.L == '*':
        max_level = '*'
    else:
        try:
            max_level = int(args.L)
            if max_level < 1:
                raise ValueError
        except ValueError:
            print("Error: -L must be a positive integer or *")
            sys.exit(1)

    items = parse_markdown_list(args.file)
    print_tree(items, max_level)

if __name__ == "__main__":
    main()

