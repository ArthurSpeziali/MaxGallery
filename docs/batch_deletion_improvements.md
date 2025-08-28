# Batch Deletion Improvements

## Problem

The original file deletion implementation failed when users had more than 25,000 files with the error:
```
maxFileCount out of range: 25000
```

This happened because the BlackBlaze B2 API has a limit of 25,000 files that can be listed in a single request.

## Solution

Implemented a new batch-based deletion system that:

1. **Processes files in smaller batches** (10,000 files per batch - 40% of the API limit for safety)
2. **Uses parallel processing** within each batch for better performance
3. **Handles partial failures gracefully** by continuing with remaining batches
4. **Provides detailed logging** for monitoring progress
5. **Includes proper error handling** and recovery

## Implementation Details

### New Module: `MaxGallery.Storage.BatchDeleter`

- **Batch Size**: 10,000 files (40% of 25,000 limit for safety)
- **Parallel Processing**: 10 files deleted concurrently within each batch
- **Timeout**: 30 seconds per file deletion
- **Delay**: 100ms between batches to be nice to the API

### Key Features

1. **Safe Batch Sizing**: Uses 40% of the API limit to avoid edge cases
2. **Progress Logging**: Logs progress after each batch completion
3. **Error Recovery**: Continues processing even if some files fail to delete
4. **Partial Success**: Returns count of successfully deleted files even if some fail
5. **Memory Efficient**: Processes files in chunks without loading everything into memory

## Usage

The API remains the same - no changes needed in calling code:

```elixir
# This now uses batch processing automatically
{:ok, deleted_count} = MaxGallery.Storage.del_all(user_id)
```

## Performance Improvements

- **Before**: Failed completely with >25,000 files
- **After**: Can handle unlimited number of files
- **Concurrency**: 10 files deleted in parallel per batch
- **Monitoring**: Detailed logs show progress and any failures

## Example Log Output

```
[info] Starting batch deletion for user abc123 with batch size 10000
[info] Processing batch of 10000 files...
[info] Batch completed: 9998 deleted, 2 failed. Total: 9998 deleted, 2 failed
[info] Processing batch of 8500 files...
[info] Batch completed: 8500 deleted, 0 failed. Total: 18498 deleted, 2 failed
[info] All batches completed: 18498 deleted, 2 failed
```

## Error Handling

- Individual file deletion failures don't stop the entire process
- Partial failures are logged with warnings
- Network errors are handled gracefully
- Authentication errors are properly propagated

## Testing

- Added unit tests for the new BatchDeleter module
- Existing integration tests continue to pass
- Error handling paths are tested

This implementation ensures that users with large amounts of data can successfully delete all their files without hitting API limits.