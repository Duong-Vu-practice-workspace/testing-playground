#!/usr/bin/env python3
"""
Git add, commit and push all services to GitHub
Usage: python3 push-all.py <github-token> <org-name>

Requires: pip install requests
"""

import sys
import os
import subprocess
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
    """Run shell command and return (success, stdout, stderr)"""
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    return result.returncode == 0, result.stdout, result.stderr


def git_add_commit_push(local_path, org, repo_name, message="Update"):
    """Git add, commit and push"""
    remote_url = f"https://{token}@github.com/{org}/{repo_name}.git"

    # Check if git repo exists
    if not os.path.exists(os.path.join(local_path, ".git")):
        print(f"  [SKIP] {repo_name}: not a git repo")
        return False

    # Check if there are changes
    success, stdout, _ = run_cmd("git status --porcelain", cwd=local_path)
    if not stdout.strip():
        print(f"  [SKIP] {repo_name}: no changes")
        return True

    # Add remote if not exists
    run_cmd("git remote remove origin", cwd=local_path)
    run_cmd(f"git remote add origin {remote_url}", cwd=local_path)

    # Rename branch to main
    run_cmd("git branch -M main", cwd=local_path)

    # Add all
    success, _, stderr = run_cmd("git add .", cwd=local_path)
    if not success:
        print(f"  [FAIL] {repo_name}: git add failed - {stderr}")
        return False

    # Commit
    success, _, stderr = run_cmd(f'git commit -m "{message}"', cwd=local_path)
    if not success and "nothing to commit" not in stderr:
        print(f"  [FAIL] {repo_name}: git commit failed - {stderr}")
        return False

    # Push
    success, stdout, stderr = run_cmd("git push -u origin main", cwd=local_path)
    if success:
        print(f"  [OK] {repo_name}")
        return True
    else:
        print(f"  [FAIL] {repo_name}: {stderr}")
        return False


def main():
    global token

    if len(sys.argv) < 3:
        print("Usage: python3 push-all.py <github-token> <org-name>")
        print("  github-token: GitHub Personal Access Token")
        print("  org-name: GitHub organization name")
        sys.exit(1)

    token = sys.argv[1]
    org = sys.argv[2]

    print("=" * 60)
    print(f"Push all repos to {org}")
    print("=" * 60)
    print()

    # Push source repos
    print("Pushing source repos...")
    for service, repo_name in SOURCE_REPOS.items():
        local_path = os.path.join(SCRIPT_DIR, "services", service)
        if os.path.exists(local_path):
            git_add_commit_push(local_path, org, repo_name, f"Update {service}")
        else:
            print(f"  [SKIP] {local_path} not found")
        time.sleep(0.5)

    print()
    print("Pushing config repos...")
    for service, repo_name in CONFIG_REPOS.items():
        local_path = os.path.join(SCRIPT_DIR, "config-repos", service)
        if os.path.exists(local_path):
            git_add_commit_push(local_path, org, repo_name, f"Update {service} config")
        else:
            print(f"  [SKIP] {local_path} not found")
        time.sleep(0.5)

    # Push Spring Cloud Config repo
    print()
    print("Pushing Spring Cloud Config repo...")
    config_path = os.path.join(SCRIPT_DIR, "config-repo-spring")
    if os.path.exists(config_path):
        git_add_commit_push(config_path, org, CONFIG_GIT_REPO, "Update config")
    else:
        print(f"  [SKIP] {config_path} not found")

    print()
    print("=" * 60)
    print("Done!")
    print("=" * 60)


if __name__ == "__main__":
    main()
