with open("iOS/FinPilotAI/project.yml", "r") as f:
    content = f.read()

old_ats = """        NSAppTransportSecurity:
          NSAllowsLocalNetworking: true"""
new_ats = """        NSAppTransportSecurity:
          NSAllowsLocalNetworking: true
          NSAllowsArbitraryLoads: true"""

content = content.replace(old_ats, new_ats)

with open("iOS/FinPilotAI/project.yml", "w") as f:
    f.write(content)
