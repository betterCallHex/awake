import re
import sys

KB = 1000
MB = 1000 * 1000


def main():
    version, download_bytes, app_bytes, app_files = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
    readme = open("README.md").read()
    download, app = kilobytes(download_bytes), kilobytes(app_bytes)
    keeping_download, caffeine_download = competitor_sizes(readme, r"\| Download \| \*\*[\d.]+ KB\*\* \| ([\d.]+ [KM]B) \(\d+× larger\) \| ([\d.]+ [KM]B) \(\d+× larger\) \|")
    keeping_app, caffeine_app = competitor_sizes(readme, r"\| Size on disk \| \*\*[\d.]+ KB\*\*, \d+ files \| ([\d.]+ [KM]B), \d+ files \(\d+×\) \| ([\d.]+ [KM]B), \d+ files \(\d+×\) \|")
    keeping_app_ratio = ratio(keeping_app, app_bytes)
    replacements = [
        (r"a [\d.]+ KB native app \(a [\d.]+ KB download\)", f"a {app} KB native app (a {download} KB download)"),
        (r"\| \*\*Awake [\d.]+\*\* \|", f"| **Awake {version}** |"),
        (r"(\| Download \| )\*\*[\d.]+ KB\*\*( \| [\d.]+ [KM]B \()\d+(× larger\) \| [\d.]+ [KM]B \()\d+(× larger\) \|)",
         rf"\g<1>**{download} KB**\g<2>{ratio(keeping_download, download_bytes)}\g<3>{ratio(caffeine_download, download_bytes)}\g<4>"),
        (r"(\| Size on disk \| )\*\*[\d.]+ KB\*\*, \d+ files( \| [\d.]+ [KM]B, \d+ files \()\d+(×\) \| [\d.]+ [KM]B, \d+ files \()\d+(×\) \|)",
         rf"\g<1>**{app} KB**, {app_files} files\g<2>{keeping_app_ratio}\g<3>{ratio(caffeine_app, app_bytes)}\g<4>"),
        (r"the Awake [\d.]+ DMG", f"the Awake {version} DMG"),
        (r"It's a \d+× larger app", f"It's a {keeping_app_ratio}× larger app"),
    ]
    for pattern, replacement in replacements:
        readme = replace_once(readme, pattern, replacement)
    open("README.md", "w").write(readme)


def kilobytes(size):
    return round(size / KB)


def competitor_sizes(readme, pattern):
    match = re.search(pattern, readme)
    if not match:
        sys.exit(f"README.md has no line matching {pattern}")
    return [to_bytes(size) for size in match.groups()]


def to_bytes(size):
    number, unit = size.split()
    return float(number) * (MB if unit == "MB" else KB)


def ratio(competitor_bytes, awake_bytes):
    return round(competitor_bytes / awake_bytes)


def replace_once(text, pattern, replacement):
    updated, count = re.subn(pattern, replacement, text)
    if count != 1:
        sys.exit(f"README.md matched {pattern} {count} times, expected once")
    return updated


if __name__ == "__main__":
    main()
