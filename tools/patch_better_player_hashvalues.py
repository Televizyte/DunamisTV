import os
import sys
from pathlib import Path

def die(msg: str):
    print(f"[ERROR] {msg}")
    sys.exit(1)

def patch_file(path: Path) -> bool:
    before = path.read_text(encoding="utf-8")
    after = before.replace("hashValues(", "Object.hash(")

    # Some packages use hashList too; keep this safe if it exists.
    # hashList(list) => Object.hashAll(list)
    after = after.replace("hashList(", "Object.hashAll(")

    if after != before:
        path.write_text(after, encoding="utf-8")
        print(f"[PATCHED] {path}")
        return True
    else:
        print(f"[OK] {path} (no change)")
        return False

def main():
    # Typical Windows pub cache location
    localappdata = os.environ.get("LOCALAPPDATA")
    if not localappdata:
        die("LOCALAPPDATA env var not found. Are you on Windows?")

    root = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dev" / "better_player-0.0.84"
    if not root.exists():
        # Fallback: sometimes path can be 'hosted\\pub.dartlang.org' on older setups
        root2 = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dartlang.org" / "better_player-0.0.84"
        if root2.exists():
            root = root2
        else:
            die("Could not find better_player-0.0.84 in Pub cache. Run `flutter pub get` first.")

    targets = [
        root / "lib" / "src" / "hls" / "hls_parser" / "drm_init_data.dart",
        root / "lib" / "src" / "hls" / "hls_parser" / "hls_track_metadata_entry.dart",
        root / "lib" / "src" / "hls" / "hls_parser" / "scheme_data.dart",
        root / "lib" / "src" / "hls" / "hls_parser" / "variant_info.dart",
    ]

    changed_any = False
    for f in targets:
        if not f.exists():
            die(f"Target file missing: {f}")
        changed_any = patch_file(f) or changed_any

    print("\n=== RESULT ===")
    if changed_any:
        print("Patch applied successfully.")
    else:
        print("No changes were needed (maybe already patched).")

if __name__ == "__main__":
    main()
