#!/usr/bin/env python3
"""
Script to minify JavaScript files using jsmin and CSS using rcssmin.
Minifies assets/js/gtag.js (including embedded CSS) and writes the output to assets/js/custom.js.
"""

from jsmin import jsmin
from rcssmin import cssmin
import re

# Try to minify the file
try:
    with open('assets/js/gtag.js', 'r') as js_file:
        content = js_file.read()

    # Find and minify the embedded CSS
    css_pattern = r'const styles = `([^`]*)`;'
    match = re.search(css_pattern, content, re.DOTALL)
    if match:
        original_css = match.group(1)
        minified_css = cssmin(original_css)
        content = content.replace(original_css, minified_css)

    # Minify the JavaScript
    minified = jsmin(content, quote_chars="'\"`")

    with open('assets/js/custom.js', 'w') as minified_file:
        minified_file.write(minified)

    print("Minified gtag.js (with embedded CSS) to custom.js")

except FileNotFoundError as e:
    print(f"Error: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
