# v4.py
#!/usr/bin/env python3

"""
v4.py — Generic Symbol-Aware Recursive Wikipedia Crawler

Enhancements over v3.py:
- Accepts a generic list of symbols from the user
- Can be applied to any topic, not just general relativity
- Recursively crawls pages that contain the specified symbols
- Outputs Markdown with math blocks and linked formula dependencies
"""

import re
import sys
import time
import requests
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from markdownify import markdownify as md

BASE_DOMAIN = "en.wikipedia.org"
REQUEST_DELAY = 1.0  # seconds
MAX_LINKS_PER_PAGE = 15  # safety throttle

session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0 (compatible; wiki-md-generic-symbol-crawler)"})


def clean_math(text: str) -> str:
    text = re.sub(r"\{\{Math\|(.*?)\}\}", r"$\1$", text, flags=re.DOTALL)
    text = re.sub(r"<math.*?>(.*?)</math>", r"$\1$", text, flags=re.DOTALL)
    return text


def extract_math_blocks(html: str):
    results = []
    results += re.findall(r"\{\{Math\|(.*?)\}\}", html, flags=re.DOTALL)
    results += re.findall(r"<math.*?>(.*?)</math>", html, flags=re.DOTALL)
    return [m.strip() for m in results if m.strip()]


def contains_relevant_symbols(math_blocks, symbols):
    for block in math_blocks:
        for sym in symbols:
            if sym in block:
                return True
    return False


def is_valid_wiki_link(href: str) -> bool:
    if not href or not href.startswith("/wiki/"):
        return False
    bad_prefixes = ("/wiki/Special:", "/wiki/Help:", "/wiki/File:", "/wiki/Talk:", "/wiki/Category:", "/wiki/Portal:")
    return not href.startswith(bad_prefixes)


def fetch_page(url: str) -> str:
    print(f"[+] Fetching {url}")
    r = session.get(url, timeout=30)
    r.raise_for_status()
    time.sleep(REQUEST_DELAY)
    return r.text


def extract_links(soup: BeautifulSoup):
    links = []
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if is_valid_wiki_link(href):
            links.append(urljoin("https://en.wikipedia.org", href))
    return links[:MAX_LINKS_PER_PAGE]


def crawl(url: str, depth: int, visited: set, output_lines: list, symbols: list):
    if depth < 0 or url in visited:
        return

    visited.add(url)

    try:
        html = fetch_page(url)
    except Exception as e:
        print(f"[!] Failed: {e}")
        return

    soup = BeautifulSoup(html, "html.parser")
    title_tag = soup.find("h1")
    title = title_tag.get_text(strip=True) if title_tag else url

    output_lines.append(f"\n# {title}\n")
    output_lines.append(f"Source: {url}\n")

    math_blocks = extract_math_blocks(html)

    if math_blocks:
        output_lines.append("## Extracted formulas\n")
        for m in math_blocks:
            output_lines.append(f"- ${m}$")
        output_lines.append("")

    content = soup.find("div", {"id": "mw-content-text"})
    if content:
        markdown = md(str(content), heading_style="ATX")
        markdown = clean_math(markdown)
        markdown = re.sub(r"\n{3,}", "\n\n", markdown)
        output_lines.append("## Page content\n")
        output_lines.append(markdown)

    # Base case: stop if no relevant symbols
    if not contains_relevant_symbols(math_blocks, symbols):
        print("[i] No relevant symbols — base case reached")
        return

    # Recurse into links
    if depth > 0:
        links = extract_links(soup)
        print(f"[i] Following {len(links)} links (depth remaining: {depth})")
        for link in links:
            crawl(link, depth - 1, visited, output_lines, symbols)


def main():
    if len(sys.argv) < 4:
        print("Usage: v4.py <wikipedia_url> <output.md> <symbol1,symbol2,...> [depth]")
        sys.exit(1)

    start_url = sys.argv[1]
    output_file = sys.argv[2]
    symbols = sys.argv[3].split(',')
    depth = int(sys.argv[4]) if len(sys.argv) > 4 else 2

    visited = set()
    output_lines = ["# Generic Symbol-Aware Recursive Wikipedia Math Crawl\n"]

    crawl(start_url, depth, visited, output_lines, symbols)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(output_lines))

    print(f"[✓] Saved to {output_file}")


if __name__ == "__main__":
    main()
