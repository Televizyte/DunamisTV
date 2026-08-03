import os
import shutil
from pathlib import Path

def die(msg: str):
    print(f"[ERROR] {msg}")
    raise SystemExit(1)

def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8")

def write_text(p: Path, s: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

def patch_hashvalues(root: Path) -> int:
    # Patch all Dart files under better_player
    count = 0
    for f in root.rglob("*.dart"):
        txt = read_text(f)
        new = txt.replace("hashValues(", "Object.hash(").replace("hashList(", "Object.hashAll(")
        if new != txt:
            write_text(f, new)
            count += 1
    return count

def main():
    project_root = Path(__file__).resolve().parents[1]
    tools_dir = project_root / "tools"
    third_party_dir = project_root / "third_party"
    local_pkg_dir = third_party_dir / "better_player"

    localappdata = os.environ.get("LOCALAPPDATA")
    if not localappdata:
        die("LOCALAPPDATA not found. This script is for Windows.")

    cache_a = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dev" / "better_player-0.0.84"
    cache_b = Path(localappdata) / "Pub" / "Cache" / "hosted" / "pub.dartlang.org" / "better_player-0.0.84"
    src = cache_a if cache_a.exists() else cache_b if cache_b.exists() else None
    if not src:
        die("Could not find better_player-0.0.84 in Pub cache. Run `flutter pub get` first.")

    print(f"[INFO] Found better_player in cache: {src}")

    # Copy to local third_party/better_player
    if local_pkg_dir.exists():
        print(f"[INFO] Removing existing local override: {local_pkg_dir}")
        shutil.rmtree(local_pkg_dir)

    print(f"[INFO] Copying to local override: {local_pkg_dir}")
    shutil.copytree(src, local_pkg_dir)

    # Patch hashValues -> Object.hash across local override
    patched_files = patch_hashvalues(local_pkg_dir)
    print(f"[INFO] Patched {patched_files} dart file(s) in local override.")

    # Print the exact pubspec snippet to add
    snippet = """
dependency_overrides:
  better_player:
    path: third_party/better_player
""".strip()

    print("\n=== DO THIS NOW ===")
    print("1) Open pubspec.yaml")
    print("2) Add this block at the BOTTOM (top-level, not inside 'dependencies'):\n")
    print(snippet)
    print("\n3) Then run:")
    print("   flutter clean")
    print("   flutter pub get")
    print("   flutter run -d chrome")
    print("\n[DONE]")

if __name__ == "__main__":
    main()
