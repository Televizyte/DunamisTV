import os
import shutil
from pathlib import Path

def die(msg: str):
    print(f"[ERROR] {msg}")
    raise SystemExit(1)

def patch_hashvalues(pkg_root: Path) -> int:
    """
    Replace deprecated hashValues/hashList calls used by older packages.
    """
    changed = 0
    for f in pkg_root.rglob("*.dart"):
        try:
            before = f.read_text(encoding="utf-8")
        except Exception:
            continue

        after = before.replace("hashValues(", "Object.hash(")
        after = after.replace("hashList(", "Object.hashAll(")

        if after != before:
            f.write_text(after, encoding="utf-8")
            changed += 1
    return changed

def main():
    project_root = Path(__file__).resolve().parents[1]
    third_party_dir = project_root / "third_party"
    local_pkg_dir = third_party_dir / "better_player"

    localappdata = os.environ.get("LOCALAPPDATA")
    if not localappdata:
        die("LOCALAPPDATA not found. This script is intended for Windows.")

    # Possible pub cache roots
    cache1 = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dev" / "better_player-0.0.84"
    cache2 = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dartlang.org" / "better_player-0.0.84"

    src = cache1 if cache1.exists() else cache2 if cache2.exists() else None
    if not src:
        die("better_player-0.0.84 not found in Pub cache. Run `flutter pub get` first.")

    print(f"[INFO] Project root: {project_root}")
    print(f"[INFO] Pub cache source: {src}")

    # Create third_party folder
    third_party_dir.mkdir(parents=True, exist_ok=True)

    # Fresh copy local package
    if local_pkg_dir.exists():
        print(f"[INFO] Removing existing local override: {local_pkg_dir}")
        shutil.rmtree(local_pkg_dir)

    print(f"[INFO] Copying better_player to: {local_pkg_dir}")
    shutil.copytree(src, local_pkg_dir)

    # Patch deprecated hash functions in local override
    changed = patch_hashvalues(local_pkg_dir)
    print(f"[INFO] Patched {changed} Dart file(s) in local override.")

    # Sanity check: ensure pubspec exists in local package root
    if not (local_pkg_dir / "pubspec.yaml").exists():
        die(f"Local override seems incomplete: missing {local_pkg_dir / 'pubspec.yaml'}")

    print("\n=== SUCCESS ===")
    print("Local override created at: third_party/better_player")
    print("Now run:")
    print("  flutter clean")
    print("  flutter pub get")
    print("  flutter run -d chrome")

if __name__ == "__main__":
    main()
