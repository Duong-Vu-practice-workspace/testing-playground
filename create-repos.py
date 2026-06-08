#!/usr/bin/env python3
"""
Create all GitHub repos and setup organization secrets
Usage: python3 create-repos.py <github-token> <org-name> [private]

Requires: pip install requests
"""

import sys
import requests
import time

def create_repo(token, org, name, description="", private=False):
    """Create a GitHub repo in organization"""
    url = f"https://api.github.com/orgs/{org}/repos"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "name": name,
        "description": description,
        "private": private,
        "auto_init": False
    }
    
    resp = requests.post(url, headers=headers, json=data)
    if resp.status_code == 201:
        print(f"  [OK] {name}")
        return True
    elif resp.status_code == 422:
        print(f"  [SKIP] {name} already exists")
        return True
    else:
        print(f"  [FAIL] {name}: {resp.status_code} - {resp.text}")
        return False

def create_org_secret(token, org, secret_name, secret_value, repos=None):
    """Create organization secret"""
    url = f"https://api.github.com/orgs/{org}/actions/secrets/{secret_name}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # Note: GitHub API requires sodium-encrypted value
    # For simplicity, we'll use the plaintext endpoint (less secure but works)
    # In production, use libsodium to encrypt
    
    if repos:
        # Visible to specific repos
        data = {
            "encrypted_value": secret_value,  # Should be encrypted in production
            "visibility": "selected",
            "selected_repository_ids": repos
        }
    else:
        # Visible to all repos
        data = {
            "encrypted_value": secret_value,
            "visibility": "all"
        }
    
    resp = requests.put(url, headers=headers, json=data)
    if resp.status_code in [201, 204]:
        print(f"  [OK] Secret {secret_name} created")
        return True
    else:
        print(f"  [INFO] Secret {secret_name}: {resp.status_code} - {resp.text}")
        return False

def setup_org_secrets(token, org):
    """Setup organization-level secrets"""
    print()
    print("Setting up organization secrets...")
    print()
    print("NOTE: GitHub API requires encrypted values for secrets.")
    print("Please add these secrets manually via GitHub UI:")
    print()
    print(f"  1. Go to https://github.com/{org}/settings/secrets/actions")
    print("  2. Click 'New organization secret'")
    print()
    print("  Secrets to create:")
    print("  ┌─────────────────────────┬────────────────────────────────────┐")
    print("  │ Secret Name             │ Description                        │")
    print("  ├─────────────────────────┼────────────────────────────────────┤")
    print("  │ DOCKERHUB_USERNAME      │ Docker Hub username                 │")
    print("  │ DOCKERHUB_TOKEN         │ Docker Hub access token             │")
    print("  │ CONFIG_REPO_TOKEN       │ GitHub PAT with repo scope          │")
    print("  └─────────────────────────┴────────────────────────────────────┘")
    print()
    print("  3. For each secret, select visibility:")
    print("     - 'All repositories' (recommended)")
    print("     - Or select specific repos")
    print()

def get_repo_ids(token, org, repo_names):
    """Get repository IDs for selected visibility"""
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    repo_ids = []
    for name in repo_names:
        url = f"https://api.github.com/repos/{org}/{name}"
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            repo_ids.append(resp.json()["id"])
    
    return repo_ids

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 create-repos.py <github-token> <org-name> [private]")
        print("  github-token: GitHub Personal Access Token (with repo + admin:org scope)")
        print("  org-name: GitHub organization name")
        print("  private: 'true' or 'false' (default: false)")
        sys.exit(1)
    
    token = sys.argv[1]
    org = sys.argv[2]
    private = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else False
    
    print("=" * 60)
    print(f"Creating GitHub repos for {org}")
    print("=" * 60)
    print()
    
    # Source repos
    source_repos = [
        ("grading-gateway-test2", "Gateway - API Gateway for Grading Platform"),
        ("grading-assignment-service-test2", "Assignment Service - CRUD assignments"),
        ("grading-submission-service-test2", "Submission Service - Upload & Kafka"),
        ("grading-executor-service-test2", "Grading Service - Testcontainers executor"),
        ("grading-result-service-test2", "Result Service - Grading results"),
        ("grading-notification-service-test2", "Notification Service - WebSocket"),
        ("grading-config-server-test2", "Config Server - Spring Cloud Config"),
        ("grading-common-lib-test2", "Common Library - Shared code"),
    ]
    
    # Config repos
    config_repos = [
        ("grading-gateway-config-test2", "Gateway config for ArgoCD"),
        ("grading-assignment-service-config-test2", "Assignment Service config for ArgoCD"),
        ("grading-submission-service-config-test2", "Submission Service config for ArgoCD"),
        ("grading-executor-service-config-test2", "Grading Service config for ArgoCD"),
        ("grading-result-service-config-test2", "Result Service config for ArgoCD"),
        ("grading-notification-service-config-test2", "Notification Service config for ArgoCD"),
        ("grading-config-server-config-test2", "Config Server config for ArgoCD"),
    ]
    
    # Config repo for Spring Cloud Config
    config_git_repo = [
        ("grading-config-test2", "Configuration files for all services"),
    ]
    
    print("Creating source repos...")
    for name, desc in source_repos:
        create_repo(token, org, name, desc, private)
        time.sleep(0.5)
    
    print()
    print("Creating config repos (ArgoCD)...")
    for name, desc in config_repos:
        create_repo(token, org, name, desc, private)
        time.sleep(0.5)
    
    print()
    print("Creating config repo (Spring Cloud Config)...")
    for name, desc in config_git_repo:
        create_repo(token, org, name, desc, private)
        time.sleep(0.5)
    
    # Setup organization secrets
    setup_org_secrets(token, org)
    
    print()
    print("=" * 60)
    print("Done! Created repos:")
    print("=" * 60)
    print()
    print("SOURCE REPOS (code + CI):")
    for name, _ in source_repos:
        print(f"  - {name}")
    print()
    print("CONFIG REPOS (ArgoCD CD):")
    for name, _ in config_repos:
        print(f"  - {name}")
    print()
    print("CONFIG REPO (Spring Cloud Config):")
    for name, _ in config_git_repo:
        print(f"  - {name}")

if __name__ == "__main__":
    main()
