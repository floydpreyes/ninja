"""Convert .docx files to Markdown using mammoth.

Usage:
    python docx_to_md.py <path>                 # file or directory
    python docx_to_md.py <path> -o <out_dir>    # write outputs to out_dir
    python docx_to_md.py <path> -r              # recurse into subdirectories
    python docx_to_md.py <path> --overwrite     # overwrite existing .md files

Examples:
    python docx_to_md.py .\\DR-AltusPOL-Tabletop-Runbook.docx
    python docx_to_md.py . -r -o .\\md_out

Requires: pip install mammoth
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import mammoth
except ImportError:
    sys.stderr.write(
        "ERROR: 'mammoth' is not installed. Install it with:\n"
        "    pip install mammoth\n"
    )
    sys.exit(2)


def find_docx_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() != ".docx":
            raise ValueError(f"Not a .docx file: {path}")
        return [path]
    if not path.is_dir():
        raise FileNotFoundError(path)
    pattern = "**/*.docx" if recurse else "*.docx"
    # Skip Word lock/temp files (~$foo.docx).
    return sorted(p for p in path.glob(pattern) if not p.name.startswith("~$"))


def convert_one(src: Path, dest: Path, overwrite: bool) -> tuple[bool, str]:
    if dest.exists() and not overwrite:
        return False, f"SKIP (exists): {dest}"
    dest.parent.mkdir(parents=True, exist_ok=True)
    with src.open("rb") as fh:
        result = mammoth.convert_to_markdown(fh)
    dest.write_text(result.value, encoding="utf-8")
    warn_count = len(result.messages)
    suffix = f" ({warn_count} warning{'s' if warn_count != 1 else ''})" if warn_count else ""
    return True, f"OK: {src} -> {dest}{suffix}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Convert .docx files to Markdown.")
    parser.add_argument("path", type=Path, help="Input .docx file or directory.")
    parser.add_argument(
        "-o", "--output-dir", type=Path, default=None,
        help="Directory to write .md files into (default: alongside source).",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true",
        help="Recurse into subdirectories when input is a directory.",
    )
    parser.add_argument(
        "--overwrite", action="store_true",
        help="Overwrite existing .md output files.",
    )
    args = parser.parse_args(argv)

    src_path: Path = args.path.resolve()
    out_dir: Path | None = args.output_dir.resolve() if args.output_dir else None

    try:
        files = find_docx_files(src_path, args.recurse)
    except (FileNotFoundError, ValueError) as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        return 1

    if not files:
        sys.stderr.write(f"No .docx files found under {src_path}\n")
        return 1

    base_dir = src_path if src_path.is_dir() else src_path.parent
    converted = skipped = failed = 0

    for docx in files:
        if out_dir is not None:
            rel = docx.relative_to(base_dir) if docx.is_relative_to(base_dir) else Path(docx.name)
            dest = (out_dir / rel).with_suffix(".md")
        else:
            dest = docx.with_suffix(".md")

        try:
            ok, msg = convert_one(docx, dest, args.overwrite)
        except Exception as exc:  # noqa: BLE001 - report and continue
            failed += 1
            print(f"FAIL: {docx} -> {dest}: {exc}")
            continue

        print(msg)
        if ok:
            converted += 1
        else:
            skipped += 1

    print(f"\nDone. converted={converted} skipped={skipped} failed={failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
