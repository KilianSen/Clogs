import json
import os
import urllib.request
import re

# Configuration
REPOS = {
    "FRONTEND_VERSION": "kiliansen/clogsweb",
    "BACKEND_VERSION": "kiliansen/clogsserver",
    "AGENTS_VERSION": "kiliansen/clogsagent"
}

VERSIONS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "versions.env")

def get_latest_tag(repo_name):
    url = f"https://api.github.com/repos/{repo_name}/releases/latest"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            return data.get("tag_name")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            # No releases found, try tags
            url = f"https://api.github.com/repos/{repo_name}/tags"
            try:
                with urllib.request.urlopen(url) as response:
                    data = json.loads(response.read().decode())
                    if data and isinstance(data, list):
                        return data[0].get("name")
            except Exception as e2:
                print(f"Error fetching tags for {repo_name}: {e2}")
        else:
            print(f"Error fetching release for {repo_name}: {e}")
    except Exception as e:
        print(f"Error fetching {repo_name}: {e}")
    return "main" # Fallback

def update_versions_file():
    new_versions = {}
    print("Fetching latest versions...")
    for key, repo in REPOS.items():
        tag = get_latest_tag(repo)
        print(f"{repo}: {tag}")
        new_versions[key] = tag

    # Read existing file
    if os.path.exists(VERSIONS_FILE):
        with open(VERSIONS_FILE, 'r') as f:
            lines = f.readlines()
    else:
        lines = []

    # Update lines
    updated_lines = []
    keys_found = set()

    for line in lines:
        match = False
        for key, version in new_versions.items():
            if line.startswith(f"{key}="):
                updated_lines.append(f"{key}={version}\n")
                keys_found.add(key)
                match = True
                break
        if not match:
            updated_lines.append(line)

    # Add missing keys
    for key, version in new_versions.items():
        if key not in keys_found:
            updated_lines.append(f"{key}={version}\n")

    # Write back
    with open(VERSIONS_FILE, 'w') as f:
        f.writelines(updated_lines)

    print(f"Updated {VERSIONS_FILE}")

if __name__ == "__main__":
    update_versions_file()

