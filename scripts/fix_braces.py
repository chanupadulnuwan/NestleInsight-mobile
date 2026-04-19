import sys

file_path = 'c:/NestleInsight/nestleinsight-adminweb/src/pages/tm/TmApprovalsPage.tsx'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# The problematic block:
#     } finally {
#       setApprovingUserId(null)
#     }
#   }
# 
#   const handleReviewOutlet = async (
#     ...
#     }
#   }
#   }
# 
#   if (!user) {

# I will replace the whole TmApprovalsPage function body to ensure it is correct.
# Actually, I'll just find the "handleReviewOutlet" function and the extra brace.

search_pattern = """    } finally {
      setApprovingUserId(null)
    }
  }

  const handleReviewOutlet = async ("""

# Let's try to just find the part that's wrong.
# Line 439 was `  }`
# Line 440 was `  }`
# Line 441 was empty.

bad_block = """    } finally {
      setApprovingUserId(null)
    }
  }

  const handleReviewOutlet = async ("""

# I will use a more surgical approach.
lines = text.splitlines()
found_idx = -1
for i in range(len(lines)):
    if 'setApprovingUserId(null)' in lines[i] and '}' in lines[i+1]:
        found_idx = i
        break

if found_idx != -1:
    # We found the end of handleApproveUser
    # Now look for the end of handleReviewOutlet
    for j in range(found_idx + 1, len(lines)):
        if 'const handleReviewOutlet' in lines[j]:
            # Found it. Now find its closing brace and the extra one.
            brace_count = 0
            for k in range(j, len(lines)):
                brace_count += lines[k].count('{')
                brace_count -= lines[k].count('}')
                if brace_count == 0 and '}' in lines[k]:
                    # Found the closing brace of handleReviewOutlet
                    # Check if next line is an extra brace
                    if k+1 < len(lines) and lines[k+1].strip() == '}':
                        print(f"Removing extra brace at line {k+2}")
                        del lines[k+1]
                        break
            # Also check if it was inserted inside another function.
            # handleApproveUser ends at line found_idx + 1.
            # handleReviewOutlet should start AFTER that.
            
with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
