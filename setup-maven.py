#!/usr/bin/env python3
"""
Setup local Maven settings.xml for GitHub Packages
Usage: python3 setup-maven.py <github-username> <github-token>
"""

import sys
import os

SETTINGS_TEMPLATE = """<settings>
  <servers>
    <server>
      <id>github</id>
      <username>{username}</username>
      <password>{token}</password>
    </server>
  </servers>
</settings>
"""

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 setup-maven.py <github-username> <github-token>")
        print()
        print("This creates ~/.m2/settings.xml for GitHub Packages authentication.")
        print("Required for both local development and GitHub Actions.")
        sys.exit(1)
    
    username = sys.argv[1]
    token = sys.argv[2]
    
    m2_dir = os.path.expanduser("~/.m2")
    settings_file = os.path.join(m2_dir, "settings.xml")
    
    os.makedirs(m2_dir, exist_ok=True)
    
    with open(settings_file, "w") as f:
        f.write(SETTINGS_TEMPLATE.format(username=username, token=token))
    
    print(f"Created {settings_file}")
    print()
    print("Now you can run:")
    print("  cd services/assignment-service")
    print("  mvn clean package -DskipTests")

if __name__ == "__main__":
    main()
