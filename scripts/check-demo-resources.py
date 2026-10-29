#!/usr/bin/env python3
"""Check the actual app embeds the package privacy manifest, not a source copy."""
import pathlib
import plistlib
import sys
app = pathlib.Path(sys.argv[1])
name = "JXSegmentedView"
manifest = app / (name + "_" + name + ".bundle") / "PrivacyInfo.xcprivacy"
if not manifest.is_file():
    raise SystemExit("Missing package privacy resource in app: " + str(manifest))
with manifest.open("rb") as stream:
    value = plistlib.load(stream)
if "NSPrivacyTracking" not in value:
    raise SystemExit("Invalid privacy manifest: " + str(manifest))
print("Verified application privacy resource:", manifest)
