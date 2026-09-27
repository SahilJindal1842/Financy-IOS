with open("iOS/FinPilotAI/project.yml", "r") as f:
    content = f.read()

old_prop = "      properties:\n"
new_prop = "      properties:\n        CFBundleDisplayName: Financy\n"
content = content.replace(old_prop, new_prop)

with open("iOS/FinPilotAI/project.yml", "w") as f:
    f.write(content)

