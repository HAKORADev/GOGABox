#!/usr/bin/env python3
"""Idempotently inject a <meta-data> entry into an AndroidManifest.xml.

Used by .ci/materialize-project.sh to register Godot Android plugins
(org.godotengine.plugin.v1.<Name> -> <PluginClass>) declared by each shared
plugin's plugin.meta.json, so project overlays never hardcode a backend.

Usage: inject-manifest-meta.py <AndroidManifest.xml> <meta-name> <meta-value>
Exit codes: 0 injected-or-already-present, 1 error.
"""
import sys


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 1
    path, name, value = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(path, encoding="utf-8") as f:
        src = f.read()

    if f'android:name="{name}"' in src:
        print(f"manifest-meta: {name} already present (skip)")
        return 0
    if "</application>" not in src:
        print("manifest-meta: no </application> element found", file=sys.stderr)
        return 1

    entry = (
        "        <!-- plugin registration (injected by .ci/materialize-project.sh) -->\n"
        "        <meta-data\n"
        f'            android:name="{name}"\n'
        f'            android:value="{value}" />\n\n'
    )
    src = src.replace("    </application>", entry + "    </application>", 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"manifest-meta: injected {name} -> {value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
