import re

with open('macos/Runner/MainShellViewController.swift', 'r') as f:
    content = f.read()

def replace_table_setup(match):
    setup = match.group(0)
    additional = """
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask
"""
    return setup + additional

content = re.sub(r'tableView\.delegate = self', replace_table_setup, content)

with open('macos/Runner/MainShellViewController.swift', 'w') as f:
    f.write(content)
