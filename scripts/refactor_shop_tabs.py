import sys

file_path = 'c:/NestleInsight/nestleinsight-mobile/lib/features/home/presentation/widgets/shop_owner_secondary_tabs.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add import
if "import 'package:mobile/features/home/presentation/widgets/activity_card.dart';" not in text:
    text = text.replace(
        "import 'package:mobile/features/profile/domain/shop_owner_profile.dart';",
        "import 'package:mobile/features/home/presentation/widgets/activity_card.dart';\nimport 'package:mobile/features/profile/domain/shop_owner_profile.dart';"
    )

# 2. Replace _ActivityCard with ActivityCard
text = text.replace("return _ActivityCard(activity: activity);", "return ActivityCard(activity: activity);")

# 3. Remove _ActivityCard and _ActivityMetaChip classes
# I'll use a regex-like approach or just find the line and delete until EOF or next section.
lines = text.splitlines()
new_lines = []
skip = False
for line in lines:
    if "class _ActivityCard extends StatelessWidget {" in line:
        skip = True
    if skip:
        if "class _MessageCard extends StatelessWidget {" in line:
            skip = False
            new_lines.append(line)
        continue
    new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines) + '\n')
