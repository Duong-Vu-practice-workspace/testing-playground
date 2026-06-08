#!/usr/bin/env python3
"""
Setup all repos: push code and config
Usage: python3 setup-repos.py <github-token> <org-name>

Requires: pip install requests gitpython

NOTE: Organization secrets should be set manually via GitHub UI
"""

import sys
import os
import subprocess
import requests
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

SOURCE_REPOS = {
    "gateway": "grading-gateway-test2",
    "assignment-service": "grading-assignment-service-test2",
    "submission-service": "grading-submission-service-test2",
    "grading-service": "grading-executor-service-test2",
    "result-service": "grading-result-service-test2",
    "notification-service": "grading-notification-service-test2",
    "config-server": "grading-config-server-test2",
    "common-lib": "grading-common-lib-test2",
}

CONFIG_REPOS = {
    "gateway": "grading-gateway-config-test2",
    "assignment-service": "grading-assignment-service-config-test2",
    "submission-service": "grading-submission-service-config-test2",
    "grading-service": "grading-executor-service-config-test2",
    "result-service": "grading-result-service-config-test2",
    "notification-service": "grading-notification-service-config-test2",
    "config-server": "grading-config-server-config-test2",
}

CONFIG_GIT_REPO = "grading-config-test2"

def run_cmd(cmd, cwd=None):
    """Run shell command"""
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    return result.returncode == 0

def push_repo(token, org, repo_name, local_path, branch="main"):
    """Push local repo to GitHub"""
    remote_url = f"https://{token}@github.com/{org}/{repo_name}.git"
    
    # Add remote
    run_cmd("git remote remove origin", cwd=local_path)
    run_cmd(f"git remote add origin {remote_url}", cwd=local_path)
    
    # Rename branch to main
    run_cmd("git branch -M main", cwd=local_path)
    
    # Push
    result = subprocess.run(
        f"git push -u origin {branch}",
        shell=True, cwd=local_path, capture_output=True, text=True
    )
    
    if result.returncode == 0:
        print(f"  [OK] Pushed to {org}/{repo_name}")
        return True
    else:
        print(f"  [FAIL] {repo_name}: {result.stderr}")
        return False

def print_secret_instructions(org):
    """Print instructions for setting up organization secrets"""
    print()
    print("=" * 60)
    print("SETUP ORGANIZATION SECRETS")
    print("=" * 60)
    print()
    print("Organization secrets are shared across all repos.")
    print("Set them once, use everywhere.")
    print()
    print(f"Go to: https://github.com/{org}/settings/secrets/actions")
    print()
    print("Create these secrets:")
    print()
    print("┌─────────────────────────┬────────────────────────────────────┐")
    print("│ Secret Name             │ Value                              │")
    print("├─────────────────────────┼────────────────────────────────────┤")
    print("│ DOCKERHUB_USERNAME      │ Your Docker Hub username            │")
    print("│ DOCKERHUB_TOKEN         │ Your Docker Hub access token        │")
    print("│ CONFIG_REPO_TOKEN       │ GitHub PAT with full repo scope     │")
    print("└─────────────────────────┴────────────────────────────────────┘")
    print()
    print("Steps:")
    print("  1. Click 'New organization secret'")
    print("  2. Enter name (e.g., DOCKERHUB_USERNAME)")
    print("  3. Enter value")
    print("  4. Select 'All repositories'")
    print("  5. Click 'Add secret'")
    print("  6. Repeat for each secret")
    print()

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 setup-repos.py <github-token> <org-name>")
        print("  github-token: GitHub Personal Access Token")
        print("  org-name: GitHub organization name")
        sys.exit(1)
    
    token = sys.argv[1]
    org = sys.argv[2]
    
    print("=" * 60)
    print(f"Setting up repos for {org}")
    print("=" * 60)
    print()
    
    # Push source repos
    print("Pushing source repos...")
    for service, repo_name in SOURCE_REPOS.items():
        local_path = os.path.join(SCRIPT_DIR, "services", service)
        if os.path.exists(local_path):
            push_repo(token, org, repo_name, local_path)
        else:
            print(f"  [SKIP] {local_path} not found")
        time.sleep(1)
    
    print()
    print("Pushing config repos...")
    for service, repo_name in CONFIG_REPOS.items():
        local_path = os.path.join(SCRIPT_DIR, "config-repos", service)
        if os.path.exists(local_path):
            push_repo(token, org, repo_name, local_path)
        else:
            print(f"  [SKIP] {local_path} not found")
        time.sleep(1)
    
    # Push Spring Cloud Config repo
    print()
    print("Pushing Spring Cloud Config repo...")
    config_path = os.path.join(SCRIPT_DIR, "config-repo-spring")
    os.makedirs(config_path, exist_ok=True)
    run_cmd("git init", cwd=config_path)
    run_cmd("git add .", cwd=config_path)
    run_cmd('git commit -m "Initial config"', cwd=config_path)
    push_repo(token, org, CONFIG_GIT_REPO, config_path)
    
    # Print secret setup instructions
    print_secret_instructions(org)
    
    print()
    print("=" * 60)
    print("Done!")
    print("=" * 60)
    print()
    print("Next steps:")
    print("  1. Setup organization secrets (see above)")
    print("  2. Apply ArgoCD applications:")
    print(f"     kubectl apply -f deploy/argocd-apps/")
    print()
    print("  3. Start cloudflared tunnel:")
    print("     bash deploy/cloudflared/setup-tunnel.sh")
    print("     docker compose -f deploy/cloudflared/docker-compose.yml up -d")

if __name__ == "__main__":
    main()
