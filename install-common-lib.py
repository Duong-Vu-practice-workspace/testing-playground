#!/usr/bin/env python3
"""
Download common-lib JAR from GitHub Releases and install to local .m2
Usage: python3 install-common-lib.py [version]

Requires: pip install requests
"""

import sys
import os
import subprocess
import requests

REPO = "Duong-Vu-practice-workspace/grading-common-lib-test2"
DEFAULT_VERSION = "1.0.0-test2"

def main():
    version = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_VERSION
    
    print(f"Downloading common-lib v{version} from GitHub Releases...")
    
    # Get latest release assets
    url = f"https://api.github.com/repos/{REPO}/releases/tags/v{version}"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    resp = requests.get(url, headers=headers)
    if resp.status_code != 200:
        print(f"Release v{version} not found. Trying latest release...")
        url = f"https://api.github.com/repos/{REPO}/releases/latest"
        resp = requests.get(url, headers=headers)
        
        if resp.status_code != 200:
            print("Error: No releases found")
            sys.exit(1)
    
    release = resp.json()
    assets = release.get("assets", [])
    
    jar_asset = None
    for asset in assets:
        if asset["name"].endswith(".jar") and "sources" not in asset["name"]:
            jar_asset = asset
            break
    
    if not jar_asset:
        print("Error: JAR file not found in release")
        sys.exit(1)
    
    print(f"Found: {jar_asset['name']}")
    print(f"Downloading from: {jar_asset['browser_download_url']}")
    
    # Download JAR
    jar_url = jar_asset["browser_download_url"]
    jar_path = f"/tmp/{jar_asset['name']}"
    
    resp = requests.get(jar_url, headers=headers)
    with open(jar_path, "wb") as f:
        f.write(resp.content)
    
    print(f"Downloaded to: {jar_path}")
    
    # Install to local .m2
    print("Installing to local Maven repository...")
    
    # Extract version from filename
    # Format: common-lib-1.0.0.jar
    jar_name = jar_asset["name"].replace(".jar", "")
    parts = jar_name.rsplit("-", 1)
    artifact_id = parts[0]
    ver = parts[1] if len(parts) > 1 else version
    
    cmd = [
        "mvn", "install:install-file",
        f"-Dfile={jar_path}",
        "-DgroupId=com.ptit.grading",
        f"-DartifactId={artifact_id}",
        f"-Dversion={ver}",
        "-Dpackaging=jar",
        "-DgeneratePom=true"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Installed {artifact_id}:{ver} to local .m2")
        print()
        print("Now you can use it in any project:")
        print()
        print("<dependencies>")
        print("    <dependency>")
        print("        <groupId>com.ptit.grading</groupId>")
        print("        <artifactId>common-lib</artifactId>")
        print(f"        <version>{ver}</version>")
        print("    </dependency>")
        print("</dependencies>")
    else:
        print(f"Error installing to .m2: {result.stderr}")
        sys.exit(1)

if __name__ == "__main__":
    main()
