#!/usr/bin/env python3
"""
Script to minify JavaScript files using jsmin.
Minifies assets/js/gtag.js and writes the output to assets/js/custom.js.
"""

from jsmin import jsmin

# Try to minify the file
try:
    with open('assets/js/gtag.js') as js_file:
        minified = jsmin(js_file.read(), quote_chars="'\"`")

    with open('assets/js/custom.js', 'w') as minified_file:
        minified_file.write(minified)

    print("Minified gtag.js to custom.js")

except FileNotFoundError as e:
    print(f"Error: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
