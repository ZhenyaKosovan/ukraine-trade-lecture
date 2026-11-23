#!/usr/bin/env python3
"""Download registered public datasets without credentials. Retain source bytes and hashes."""

import argparse
import concurrent.futures
import hashlib
import http.client
import json
from datetime import UTC, datetime
from pathlib import Path
from urllib.parse import quote, urljoin, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def fetch(source):
    path = (ROOT / source["file"]).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError("Source file path must stay inside the data folder")
    path.parent.mkdir(parents=True, exist_ok=True)
    result = dict(source)
    result["retrieved_utc"] = datetime.now(UTC).isoformat()
    try:
        if urlsplit(source["url"]).scheme != "https":
            raise ValueError("Only HTTPS dataset URLs are permitted")
        url = source["url"]
        for _ in range(6):
            parts = urlsplit(url)
            if parts.scheme != "https" or not parts.hostname:
                raise ValueError("Redirect must also use HTTPS")
            connection = http.client.HTTPSConnection(
                parts.hostname, parts.port, timeout=120
            )
            try:
                target = parts.path + ("?" + parts.query if parts.query else "")
                # Quote Unicode source filenames, leaving existing percent encodings intact.
                connection.request(
                    "GET",
                    quote(target, safe="/%?=&:;,+"),
                    headers={"User-Agent": "UkraineTradeLecture/1.0"},
                )
                response = connection.getresponse()
                if response.status in {301, 302, 303, 307, 308}:
                    url = urljoin(url, response.getheader("Location", ""))
                    continue
                if response.status != 200:
                    raise ValueError(f"HTTP {response.status}: {response.reason}")
                body = response.read(150_000_001)
                if len(body) > 150_000_000:
                    raise ValueError("File exceeds 150 MB download safety limit")
                result["resolved_url"] = url
                result["content_type"] = response.getheader("Content-Type")
                result["last_modified"] = response.getheader("Last-Modified")
                break
            finally:
                connection.close()
        else:
            raise ValueError("Too many redirects")
        if path.suffix in {".xlsx", ".zip"} and not body.startswith(b"PK"):
            raise ValueError(
                "Expected ZIP/XLSX signature; did not save possible error page"
            )
        if path.suffix == ".json" or path.suffix == ".geojson":
            json.loads(body)
        path.write_bytes(body)
        result.update(
            status="downloaded",
            bytes=len(body),
            sha256=hashlib.sha256(body).hexdigest(),
        )
    except (OSError, ValueError, http.client.HTTPException) as error:
        result.update(status="failed", error=str(error))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--id", action="append", help="Download only selected source IDs"
    )
    args = parser.parse_args()
    manifest_path = ROOT / "manifest.json"
    try:
        sources = json.loads((ROOT / "sources.json").read_text())
        previous = (
            json.loads(manifest_path.read_text()) if manifest_path.exists() else []
        )
    except (OSError, json.JSONDecodeError) as error:
        parser.error(f"Cannot read source registry or manifest: {error}")
    sources = [s for s in sources if not args.id or s["id"] in args.id]
    results = {row["id"]: row for row in previous}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for result in pool.map(fetch, sources):
            results[result["id"]] = result
            print(
                result["id"],
                result["status"],
                result.get("bytes", result.get("error")),
                flush=True,
            )
    manifest_path.write_text(
        json.dumps(list(results.values()), ensure_ascii=False, indent=2) + "\n"
    )
    if any(results[s["id"]]["status"] != "downloaded" for s in sources):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
