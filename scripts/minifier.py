#!/usr/bin/env python3
"""
Script to minify JavaScript files using jsmin and CSS using rcssmin.
Minifies assets/js/gtag.js (including embedded CSS) and writes the output to assets/js/custom.js.
"""

from jsmin import jsmin
from rcssmin import cssmin
import re
import keyword


def obfuscate_js(js_code):
    # Find all variable and function names (simple heuristic)
    reserved = set(
        [
            "break",
            "case",
            "catch",
            "class",
            "const",
            "continue",
            "debugger",
            "default",
            "delete",
            "do",
            "else",
            "export",
            "extends",
            "finally",
            "for",
            "function",
            "if",
            "import",
            "in",
            "instanceof",
            "let",
            "new",
            "return",
            "super",
            "switch",
            "this",
            "throw",
            "try",
            "typeof",
            "var",
            "void",
            "while",
            "with",
            "yield",
            "enum",
            "await",
            "implements",
            "package",
            "protected",
            "static",
            "interface",
            "private",
            "public",
            "null",
            "true",
            "false",
        ]
    )
    # Add Python keywords and some JS built-ins
    reserved.update(keyword.kwlist)
    reserved.update(
        [
            "window",
            "document",
            "console",
            "Array",
            "Object",
            "String",
            "Number",
            "Boolean",
            "Math",
            "Date",
            "RegExp",
            "Error",
            "Promise",
            "setTimeout",
            "setInterval",
            "clearTimeout",
            "clearInterval",
            "parseInt",
            "parseFloat",
            "isNaN",
            "isFinite",
            "eval",
            "JSON",
            "localStorage",
            "sessionStorage",
            "Map",
            "Set",
            "WeakMap",
            "WeakSet",
            "Symbol",
            "BigInt",
            "undefined",
        ]
    )

    # Find identifiers in var/let/const/function declarations
    pattern = re.compile(
        r"\b(var|let|const|function)\s+([a-zA-Z_$][a-zA-Z0-9_$]*)", re.MULTILINE
    )
    names = set(
        match.group(2)
        for match in pattern.finditer(js_code)
        if match.group(2) not in reserved
    )

    # Also find function parameters (simple heuristic)
    param_pattern = re.compile(r"function\s+[a-zA-Z_$][a-zA-Z0-9_$]*\s*\(([^)]*)\)")
    for match in param_pattern.finditer(js_code):
        params = match.group(1).split(",")
        for p in params:
            p = p.strip()
            if p and p not in reserved:
                names.add(p)

    # Build obfuscation map
    obf_map = {}
    for i, name in enumerate(sorted(names)):
        obf_map[name] = "_" + chr(97 + (i % 26)) + (str(i // 26) if i >= 26 else "")

    # Replace identifiers (word boundaries)
    def repl(m):
        return obf_map.get(m.group(0), m.group(0))

    if obf_map:
        id_pattern = re.compile(
            r"\b(" + "|".join(re.escape(n) for n in obf_map.keys()) + r")\b"
        )
        js_code = id_pattern.sub(repl, js_code)
    return js_code


try:
    with open("assets/js/gtag.js", "r") as js_file:
        content = js_file.read()

    # Find and minify the embedded CSS
    css_pattern = r"const styles = `([^`]*)`;"
    match = re.search(css_pattern, content, re.DOTALL)
    if match:
        original_css = match.group(1)
        minified_css = cssmin(original_css)
        content = content.replace(original_css, minified_css)

    # Obfuscate JS (simple)
    content = obfuscate_js(content)

    # Minify the JavaScript
    minified = jsmin(content, quote_chars="'\"`")

    with open("assets/js/custom.js", "w") as out_file:
        out_file.write(minified)

    print("Minified and obfuscated gtag.js (with embedded CSS) to custom.js")

except FileNotFoundError as e:
    print(f"Error: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
