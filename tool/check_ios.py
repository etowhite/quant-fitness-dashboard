import plistlib
import sys
from pathlib import Path
mode, entitlements = sys.argv[1:]
ent = plistlib.loads(Path(entitlements).read_bytes())
assert bool(ent.get("com.apple.developer.healthkit")) == (mode == "full-healthkit")
info = plistlib.loads(Path("ios/Runner/Info.plist").read_bytes())
assert info["CFBundleDisplayName"] == info["CFBundleName"] == "quant"
for key in ("NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription", "NSMotionUsageDescription", "NSFaceIDUsageDescription", "NSCameraUsageDescription"):
    assert info.get(key)
print("Verified iOS configuration and", mode, "entitlements")
