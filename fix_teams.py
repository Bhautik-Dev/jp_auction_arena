content = open(r'D:\jp_auction_arena-1\lib\features\teams\teams_screen.dart', 'r').read()

lines = content.split('\n')
print(f"Total lines: {len(lines)}")
for i, line in enumerate(lines[74:81], start=75):
    print(f"{i}: {repr(line)}")

# Line 79 (index 78) closes _showAddTeamDialog(...) {
# Line 80 (index 79) closes class TeamsScreen extends ConsumerWidget { prematurely
# Remove line 80 (index 79)
if len(lines) > 79:
    del lines[79]
    content = '\n'.join(lines)
    open(r'D:\jp_auction_arena-1\lib\features\teams\teams_screen.dart', 'w').write(content)
    print('Line 80 removed successfully!')
else:
    print('Line 79 not found')