# Group Duplication Bug Fix

## Problem Description

The group duplication system had a critical bug where folders with 2 or more items (including subfolders) would incorrectly treat subfolders as files during the duplication process. This caused errors and incorrect data structure in the duplicated hierarchy.

### Symptoms
- When duplicating a folder containing both files and subfolders
- Subfolders would be treated as files with the parent folder's name
- Files within subfolders would not be accessible or would have incorrect names
- The duplicated structure would be corrupted

### Example Scenario
```
Original Structure:
Parent/
├── file1.txt
└── Child/
    └── file2.txt

After Duplication (BUGGY):
Parent Copy/
├── file1.txt
└── Child.txt (should be a folder, but treated as file)
```

## Root Cause Analysis

The bug was located in the `mount_tree` function in `lib/max_gallery/utils.ex`. The issue was in how parameters were passed from parent groups to their child items during the duplication process.

### Technical Details

1. **Parameter Inheritance**: When processing a group, the function would create `sub_params` containing the group's encrypted name and name_iv
2. **Name Collision**: These parameters were passed down to child items via `Map.merge(params)`
3. **Overwriting**: The group's name would overwrite the child item's own name during the merge operation
4. **Incorrect Classification**: Files within subfolders would end up with the parent folder's name, causing confusion in the system

### Code Flow
```elixir
# BUGGY CODE:
sub_params = fun.(group_params, :group)  # Contains group's name/name_iv
mount_tree(subitems, sub_params, fun, key)  # Passes group name to children

# In child processing:
Map.merge(params)  # Group's name overwrites child's name
```

## Solution

The fix involved modifying the `mount_tree` function to remove the `name` and `name_iv` fields from the parameters passed to child items.

### Code Changes

**File: `lib/max_gallery/utils.ex`**

```elixir
# BEFORE (buggy):
sub_params =
  %{name: name, name_iv: name_iv, msg: msg, msg_iv: msg_iv}
  |> Map.merge(params)
  |> fun.(:group)

mount_tree(subitems, sub_params, fun, key)

# AFTER (fixed):
sub_params =
  %{name: name, name_iv: name_iv, msg: msg, msg_iv: msg_iv}
  |> Map.merge(params)
  |> fun.(:group)
  # Remove name and name_iv from sub_params to avoid overwriting child names
  |> Map.drop([:name, :name_iv])

mount_tree(subitems, sub_params, fun, key)
```

### Why This Works

1. **Group Creation**: The group is still created correctly with its own name and name_iv
2. **Parameter Cleaning**: Before passing parameters to children, we remove the group's name fields
3. **Child Independence**: Each child item can now maintain its own encrypted name
4. **Hierarchy Preservation**: The parent-child relationships are maintained through group_id

## Testing

### Test Cases Added

1. **Basic Bug Reproduction**: `test/max_gallery/group_duplicate_bug_test.exs`
   - Tests the specific scenario that triggered the bug
   - Verifies that subfolders remain as folders, not files

2. **Comprehensive Testing**: `test/max_gallery/group_duplicate_comprehensive_test.exs`
   - Tests complex hierarchies with multiple levels
   - Verifies all items maintain correct types and names

### Test Structure
```
Root/
├── file1.txt
├── SubA/
│   ├── file2.txt
│   └── SubB/
│       ├── file3.txt
│       └── file4.txt
└── SubC/
    └── file5.txt
```

## Impact

### Before Fix
- ❌ Subfolders treated as files
- ❌ Incorrect names in duplicated items
- ❌ Corrupted hierarchy structure
- ❌ Files within subfolders inaccessible

### After Fix
- ✅ Subfolders remain as folders
- ✅ All items maintain correct names
- ✅ Perfect hierarchy preservation
- ✅ All files accessible in correct locations

## Verification

The fix has been verified through:

1. **Unit Tests**: All existing tests continue to pass
2. **Bug-Specific Tests**: New tests specifically target the bug scenario
3. **Comprehensive Tests**: Complex hierarchies are properly duplicated
4. **Regression Testing**: No existing functionality was broken

## Notes

- The fix is minimal and surgical, affecting only the parameter passing logic
- No changes to the database schema or API were required
- The fix maintains backward compatibility
- Performance impact is negligible (just an additional Map.drop operation)

This fix ensures that the group duplication system now correctly handles complex hierarchies with mixed files and folders at any depth level.