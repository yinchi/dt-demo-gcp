"""UV script discovery.

Recursively find all UV scripts in the workspace.
"""

import json
import sys

import toml

# Load the main configuration file
try:
    config = toml.load("pyproject.toml")
except FileNotFoundError:
    print("❌ Configuration file not found.")
    sys.exit(1)
workspace_members = config.get("tool", {}).get("uv", {}).get("workspace", {}).get("members", [])

scripts = {}

if "project" in config and "scripts" in config["project"]:
    scripts["<global>"] = config["project"]["scripts"]
else:
    scripts["<global>"] = {}

for member in workspace_members:
    member_path = f"{member}/pyproject.toml"
    try:
        member_config = toml.load(member_path)
    except FileNotFoundError:
        print(f"❌ Configuration file not found for {member}.")
        sys.exit(1)
    if "project" in member_config and "scripts" in member_config["project"]:
        scripts[member] = member_config["project"]["scripts"]
    else:
        scripts[member] = {}

print(json.dumps(scripts, indent=4))
