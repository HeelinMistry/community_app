import os

def generate_tree(start_dir, exclude_dirs):
    tree = []
    # Ensure we have the absolute path to the starting directory
    start_path = os.path.abspath(start_dir)

    for root, dirs, files in os.walk(start_path):
        # 1. Filter out excluded directories in-place
        dirs[:] = [d for d in dirs if d not in exclude_dirs and not d.startswith('.')]

        # 2. FIXED: Use os.path.relpath (not os.relpath)
        rel_path = os.path.relpath(root, start_path)

        # Calculate level for indentation
        level = 0 if rel_path == "." else rel_path.count(os.sep) + 1

        # 3. Add the directory name
        indent = '    ' * (level - 1) if level > 0 else ""
        tree.append(f"{indent}- {os.path.basename(root)}/")

        # 4. Add files
        sub_indent = '    ' * level
        for f in files:
            if not f.startswith('.'):
                tree.append(f"{sub_indent}- {f}")
    return "\n".join(tree)

# Configuration remains the same
exclude = ['DerivedData', 'Pods', 'build', '.xcresult', 'community_app.xcodeproj', 'docs', 'Assets.xcassets', 'UI.xcodeproj']
# Make sure 'community_app' is the correct relative path from where the script runs
structure = generate_tree('community_app', exclude)

# Read existing README from the root
try:
    with open('README.md', 'r') as f:
        content = f.read()

    # Define your markers (Make sure these are unique in your README)
    # Using specific markers like [STRUCTURE_START] is safer than just "---"
    marker = "``"
    end_marker = "``"

    if marker in content and end_marker in content:
        before = content.split(marker)[0]
        after = content.split(end_marker)[1]
        new_content = f"{before}{marker}\n```\n{structure}\n```\n{end_marker}{after}"

        with open('README.md', 'w') as f:
            f.write(new_content)
        print("Successfully updated README.md structure.")
    else:
        print(f"Markers {marker} and {end_marker} not found in README.md")
except FileNotFoundError:
    print("README.md not found in the root directory.")
