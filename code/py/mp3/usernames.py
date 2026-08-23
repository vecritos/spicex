import asyncio
import re
from pathlib import Path

from playwright.async_api import async_playwright


PLAYLIST_RE = re.compile(
    r"https://open\.spotify\.com/playlist/[A-Za-z0-9]+"
)


async def scrape_playlist_urls(profile_url: str):
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True
        )

        page = await browser.new_page(
            viewport={
                "width": 1920,
                "height": 1080,
            }
        )

        print(f"Opening: {profile_url}")

        await page.goto(
            profile_url,
            wait_until="domcontentloaded",
            timeout=60000
        )

        # Give Spotify's frontend time to render.
        await page.wait_for_timeout(5000)

        found = set()
        previous_count = 0
        stable_iterations = 0

        while True:
            # Collect every href currently present.
            hrefs = await page.locator("a").evaluate_all(
                """
                elements => elements
                    .map(e => e.href)
                    .filter(Boolean)
                """
            )

            for href in hrefs:
                match = PLAYLIST_RE.search(href)

                if match:
                    found.add(match.group(0))

            print(
                f"Found {len(found)} playlist URLs"
            )

            # Stop after the page stops producing new playlists.
            if len(found) == previous_count:
                stable_iterations += 1
            else:
                stable_iterations = 0

            if stable_iterations >= 3:
                break

            previous_count = len(found)

            # Scroll down.
            await page.evaluate(
                """
                window.scrollTo(
                    0,
                    document.body.scrollHeight
                );
                """
            )

            await page.wait_for_timeout(2000)

        await browser.close()

        return sorted(found)


async def main():
    username = input(
        "Spotify username/profile URL: "
    ).strip()

    if not username.startswith("http"):
        profile_url = (
            "https://open.spotify.com/user/"
            + username
        )
    else:
        profile_url = username

    urls = await scrape_playlist_urls(
        profile_url
    )

    output = Path("playlist_urls.txt")

    output.write_text(
        "\n".join(urls) + "\n",
        encoding="utf-8"
    )

    print()
    print(f"Found {len(urls)} playlists")
    print(f"Saved to: {output.resolve()}")


if __name__ == "__main__":
    asyncio.run(main())