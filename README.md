# Permission Sync Script

A bash script to compare and synchronize complete file permissions (mode bits, user, group) between two systems with comprehensive safety features, automatic backups, and full audit trails.

## 🛡️ Safety Features

- ✅ **Interactive Prompts**: Confirms directory and filename choices
- ✅ **Default Backups (Opt-out)**: Creates timestamped backups before changes (you can decline if needed)
- ✅ **Temporary Working Directory**: Isolates all operations with automatic cleanup
- ✅ **Confirmation Before Changes**: Requires explicit approval before modifications
- ✅ **Restore Capability**: Easy rollback from any backup
- ✅ **Complete Audit Trail**: Detailed logging of all operations

## Features

- ✅ Generate permission snapshot with interactive configuration
- ✅ Compare permissions (mode, user, group) between systems
- ✅ Interactive permission fixing with confirmation prompts
- ✅ Syncs mode bits (755, 644, etc.) AND ownership (user:group)
- ✅ Versioned backups with timestamps
- ✅ Restore from backup functionality
- ✅ Color-coded output for easy reading
- ✅ Detailed logging with timestamps
- ✅ Automatic cleanup of temporary files

## Quick Start

### Step 1: On System A (Reference System)

Run the scan (it will prompt you for settings):

```bash
chmod +x permission_sync.sh
./permission_sync.sh --scan
```

**The script will ask:**
1. ✓ Use default directory `/opt/starfish`? (yes/no) [yes]
2. ✓ Use suggested registry name? (yes/no) [yes]

**Output:**
```
✓ Registry saved: permissions_sync_registry_systemA_20241127_103045.txt
```

### Step 2: Transfer to System B

```bash
scp permission_sync.sh permissions_sync_registry_systemA_*.txt user@systemB:/tmp/
```

### Step 3: On System B (Target System)

#### Option A: Compare Only (Safe - No Changes)

```bash
cd /tmp
chmod +x permission_sync.sh
./permission_sync.sh --compare permissions_sync_registry_systemA_20241127_103045.txt
```

#### Option B: Fix with Backup (Recommended)

```bash
sudo ./permission_sync.sh --fix permissions_sync_registry_systemA_20241127_103045.txt
```

**The script will:**
1. ✓ Detect or prompt for target directory
2. ✓ Ask for confirmation to proceed
3. ✓ Offer to create a backup (recommended: yes)
4. ✓ Show all changes as they happen
5. ✓ Save backup to timestamped directory
6. ✓ Provide restore command if needed

## Command Reference

| Command | Description |
|---------|-------------|
| `--scan` | Generate permission snapshot (interactive - prompts for directory and filename) |
| `--compare FILE` | Compare current system with reference FILE (read-only) |
| `--fix FILE` | Interactive compare and fix (offers backup - default yes) |
| `--restore FILE` | Restore permissions from a backup file |
| `--list-backups` | List all available backup files |
| `--help` | Show usage information |

## Flexible Sync Options

Control exactly what gets synced with optional flags:

| Flag | Effect |
|------|--------|
| `--user-only` | Sync only user ownership |
| `--group-only` | Sync only group ownership |
| `--perms-only` | Sync only permission mode bits (755, 644, etc.) |
| `--no-user` | Skip user (sync group and permissions) |
| `--no-group` | Skip group (sync user and permissions) |
| `--no-perms` | Skip permissions (sync user and group only) |

**Default:** Syncs everything (user, group, and permissions)

### Examples

```bash
# Sync only user ownership
sudo ./permission_sync.sh --fix --user-only registry.txt

# Sync only permission mode bits
sudo ./permission_sync.sh --fix --perms-only registry.txt

# Sync user and group, but not permissions
sudo ./permission_sync.sh --fix --no-perms registry.txt

# Compare only group ownership differences
./permission_sync.sh --compare --group-only registry.txt

# Restore only permissions from backup
sudo ./permission_sync.sh --restore --perms-only backup.txt
```

## Interactive Prompts

### During Scan (--scan)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target Directory Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Default directory: /opt/starfish

Use default directory? (yes/no) [yes]: yes
✓ Using directory: /opt/starfish

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Registry File Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Suggested name: permissions_sync_registry_systemA_20241127_103045.txt

Use suggested name? (yes/no) [yes]: yes
✓ Registry will be saved as: permissions_sync_registry_systemA_20241127_103045.txt
```

### During Fix (--fix)

```
⚠ WARNING: Permission Modification Mode
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This will compare and potentially modify file ownership.
A backup will be created before making any changes.

Continue? (yes/no): yes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target Directory Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Detected from registry: /opt/starfish

Use this directory? (yes/no) [yes]: yes

Create backup before making changes? (yes/no) [yes]: yes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Creating Backup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Backup created successfully
  Location: .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt
  Files backed up: 156
```

## Output Examples

### Scan Output
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scanning Permissions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
System: systemA
Directory: /opt/starfish
Output file: ./permissions_sync_registry_systemA_20241127_103045.txt

✓ Scan completed successfully
  Files scanned: 156
  Registry saved: ./permissions_sync_registry_systemA_20241127_103045.txt
  Log saved: ./scan_20241127_103045.log

✓ Ready to transfer to other system
```

### Compare Output
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Permission Comparison Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
System: systemB
Reference: permissions_sync_registry_systemA_20241127_103045.txt
Target Directory: /opt/starfish
Mode: COMPARE ONLY
Started: Wed Nov 27 10:45:22 2024
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✗ DIFFERENT: /opt/starfish/config
  Expected: appuser:appgroup (644)
  Current:  root:root (644)

✗ DIFFERENT: /opt/starfish/logs
  Expected: loguser:loggroup (755)
  Current:  root:root (755)

⚠ MISSING: /opt/starfish/data/temp.txt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total files in reference: 156
Files with differences: 5
Missing files: 1

Run with --fix flag to apply changes
Log saved to: ./compare_20241127_104500.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Fix Output
```
✗ DIFFERENT: /opt/starfish/config
  Expected: appuser:appgroup (644)
  Current:  root:root (755)
  ✓ FIXED ownership
  ✓ FIXED permissions

✗ DIFFERENT: /opt/starfish/logs
  Expected: loguser:loggroup (755)
  Current:  loguser:loggroup (644)
  ✓ FIXED permissions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total files in reference: 156
Files with differences: 5
Missing files: 1
Successfully fixed: 5
Failed to fix: 0

Backup available at:
  .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt

To restore from backup, run:
  ./permission_sync.sh --restore ".permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt"

Log saved to: ./compare_fix_20241127_104523.log
Working directory preserved: .permission_sync_20241127_104523
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Directory Structure

After running operations, you'll see:

```
your-working-directory/
├── permission_sync.sh                                    # The script
├── permissions_sync_registry_systemA_20241127_103045.txt # Registry file (from scan)
├── scan_20241127_103045.log                              # Scan operation log
├── compare_20241127_104500.log                           # Compare operation log
├── compare_fix_20241127_104523.log                       # Fix operation log
└── .permission_sync_20241127_104523/                     # Working directory (preserved if backup created)
    ├── backups/
    │   └── ownership_backup_20241127_104523.txt          # Versioned backup
    └── permission_sync_20241127_104523.log               # Detailed operation log
```

**Key Points:**
- Working directories are named `.permission_sync_<timestamp>`
- Backups are automatically versioned with timestamps
- Logs are saved to both the working directory and main directory
- Working directory is **preserved only when a backup is created** (if you answered "yes" to the backup prompt)
- Automatic cleanup removes working directory if no backup was created

## Audit Trail

All changes are logged with full details:

```
[2024-11-27 10:45:45] Starting permission comparison
[2024-11-27 10:45:45] Reference file: permissions_sync_registry_systemA_20241127_103045.txt
[2024-11-27 10:45:45] Fix mode: true
[2024-11-27 10:45:45] Working directory created: .permission_sync_20241127_104523
[2024-11-27 10:45:45] Backup directory created: .permission_sync_20241127_104523/backups
[2024-11-27 10:45:45] Creating backup of current permissions
[2024-11-27 10:45:46] Backup created: .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt (156 files)
[2024-11-27 10:45:46] ACTION: FIXED_OWNERSHIP | FILE: /opt/starfish/config | OLD: root:root | NEW: appuser:appgroup
[2024-11-27 10:45:46] ACTION: FIXED_PERMISSIONS | FILE: /opt/starfish/config | OLD: 755 | NEW: 644
[2024-11-27 10:45:47] ACTION: FIXED_PERMISSIONS | FILE: /opt/starfish/logs | OLD: 644 | NEW: 755
[2024-11-27 10:45:48] Comparison complete: 156 total files, 5 different, 0 missing, 5 fixed, 0 failed
```

## Backup and Restore

### Automatic Backups

Backups are created automatically when using `--fix`:

```bash
sudo ./permission_sync.sh --fix permissions_sync_registry_systemA_20241127_103045.txt
```

**Backup naming:** `ownership_backup_YYYYMMDD_HHMMSS.txt`

### List Backups

```bash
./permission_sync.sh --list-backups
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Available Backups
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[1] 20241127_104523 (Size: 24K)
     .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt
[2] 20241127_110015 (Size: 24K)
     .permission_sync_20241127_110015/backups/ownership_backup_20241127_110015.txt
```

### Restore from Backup

```bash
sudo ./permission_sync.sh --restore ".permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt"
```

**Using glob patterns:**
```bash
# This works if only ONE backup matches the pattern
sudo ./permission_sync.sh --restore .permission_sync_*/backups/ownership_backup_*.txt
```

**Important:** When using glob patterns (wildcards like `*`), ensure only one file matches. If multiple backups match, the shell will expand the pattern into multiple arguments and the command will fail. Use `--list-backups` to see available backups and specify the exact filename when in doubt.

The restore process:
1. Shows the target directory from backup header
2. Prompts for confirmation
3. Restores ownership and permissions (respecting sync flags)
4. Logs all restored files
5. Reports success/failure counts

## Requirements

- Bash 4.0+
- GNU/Linux environment (tested on Ubuntu/Debian/RHEL)
    - GNU `find` with `-printf` support
    - GNU `stat` with `-c` format options
    - Standard tools: `grep`, `sed`, `cut`, `du`, `hostname`, `xargs`, `chmod`, `chown`
- Root/sudo access for fixing permissions
- Both systems must have users/groups that match

**Note:** This script uses GNU-specific extensions. macOS/BSD systems may require adjustments or GNU coreutils installation.

## Important Notes

### User/Group Existence

The script will attempt to set ownership to the users/groups from System A. If those users/groups don't exist on System B, the `chown` command will fail.

**Solution**: Create matching users/groups on System B first, or modify the reference file.

### Permissions Required

- **Scanning**: Read access to `/opt/starfish`
- **Comparing**: Read access to `/opt/starfish`
- **Fixing**: Root/sudo access (typically required for `chown`)

### Safety Features

1. **Dry-run first**: Always run `--compare` before `--fix`
2. **Interactive prompts**: The `--fix` option asks for confirmation
3. **Audit logging**: All changes are logged with before/after states
4. **Error handling**: Failed operations are reported but don't stop the script

## Troubleshooting

### "Permission denied" errors

**Problem**: Cannot change ownership  
**Solution**: Run with `sudo`

```bash
sudo ./permission_sync.sh --fix permissions_sync_registry_systemA_20241127_103045.txt
```

### "User does not exist" errors

**Problem**: User from System A doesn't exist on System B  
**Solution**: Create the user first or check the compare output

```bash
# Check which users are needed
./permission_sync.sh --compare permissions_sync_registry_systemA_20241127_103045.txt

# Create user (example)
sudo useradd appuser
sudo groupadd appgroup
```

### Need to rollback changes

**Problem**: Fixed permissions but something went wrong  
**Solution**: Use the backup that was automatically created

```bash
# List available backups
./permission_sync.sh --list-backups

# Restore from the backup
sudo ./permission_sync.sh --restore ".permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt"
```

### Can't find my backup

**Problem**: Working directory was cleaned up  
**Solution**: Working directories are only preserved when a backup is created. If you declined the backup prompt, the directory was cleaned up automatically.

```bash
# The working directory is preserved after --fix operations
# only if you created a backup (answered 'yes' to the backup prompt).
# It's named: .permission_sync_<timestamp>
ls -la .permission_sync_*
```

### Want to change target directory

**Problem**: Need to scan or compare a different directory  
**Solution**: The script will prompt you. Just say "no" to the default and enter your path.

```
Use default directory? (yes/no) [yes]: no
Enter target directory path: /custom/path
```

### Want custom registry filename

**Problem**: Don't like the suggested filename  
**Solution**: Decline the suggestion and provide your own name

```
Use suggested name? (yes/no) [yes]: no
Enter registry filename: my_custom_registry.txt
```

## Advanced Usage

### Using Different Directories on Different Systems

System A uses `/opt/starfish`, but System B uses `/opt/application`:

```bash
# On System A
./permission_sync.sh --scan
# Accept /opt/starfish

# On System B
./permission_sync.sh --compare permissions_sync_registry_systemA_20241127_103045.txt
# When prompted, change to /opt/application
```

**Note**: This only works if the subdirectory structure is the same.

### Multiple Comparison Runs

Run multiple comparisons without cleanup:

```bash
# First comparison
./permission_sync.sh --compare registry.txt

# Second comparison (different day)
./permission_sync.sh --compare registry.txt

# Each creates its own timestamped log
ls -l compare_*.log
```

### Scheduled Comparison (Cron)

For automated monitoring (compare only, no fixes):

```bash
# Add to crontab
0 2 * * * cd /path/to/script && ./permission_sync.sh --compare registry.txt >> /var/log/daily_perm_check.log 2>&1
```

### Generate Multiple Registry Snapshots

Track changes over time:

```bash
# Weekly snapshot
./permission_sync.sh --scan
# Creates: permissions_sync_registry_systemA_20241127_103045.txt

# Next week
./permission_sync.sh --scan
# Creates: permissions_sync_registry_systemA_20241203_103045.txt

# Compare the two
diff permissions_sync_registry_systemA_20241127_103045.txt \
     permissions_sync_registry_systemA_20241203_103045.txt
```

### Preserving Backups Long-Term

```bash
# After a successful fix, move the backup to a safe location
cp .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt \
   /backup/archive/starfish_permissions_20241127.txt

# Now you can safely remove the working directory
rm -rf .permission_sync_20241127_104523
```

### Partial Directory Sync

To sync only a subdirectory, modify the registry file:

```bash
# Create registry as usual
./permission_sync.sh --scan

# Filter to only /opt/starfish/config
grep "^/opt/starfish/config" permissions_sync_registry_systemA_20241127_103045.txt > config_only.txt

# Use the filtered registry
./permission_sync.sh --compare config_only.txt
```

## Best Practices

1. **Always compare before fixing**
   ```bash
   ./permission_sync.sh --compare registry.txt
   # Review output, then:
   sudo ./permission_sync.sh --fix registry.txt
   ```

2. **Always create backups** (default behavior)
    - Backups are automatic with `--fix`
    - Keep working directory until verified

3. **Test on non-production first**
    - Run on a test system before production
    - Verify all users/groups exist

4. **Keep registry files versioned**
    - Use the auto-generated timestamped names
    - Store in version control if appropriate

5. **Review logs after operations**
   ```bash
   less compare_fix_20241127_104523.log
   ```

6. **Preserve backups for important changes**
   ```bash
   # Copy to permanent location
   cp .permission_sync_*/backups/ownership_backup_*.txt /backup/archive/
   ```

## Version History

- **2.0** (2024-11-28): Major Safety and Usability Update
    - ✨ Interactive prompts for directory and filename selection
    - ✨ Default backups with opt-out capability (timestamped)
    - ✨ Dedicated temporary working directories
    - ✨ Restore functionality from backups
    - ✨ List backups command
    - ✨ Automatic cleanup (preserves when backups created)
    - ✨ Enhanced logging with summary statistics
    - ✨ Improved user prompts and confirmations
    - ✨ Better error handling and validation
    - ✨ **Full permission syncing: mode bits (chmod) AND ownership (chown)**
    - ✨ **Flexible sync options: sync user, group, permissions, or any combination**
    - 🔒 Removed unsafe auto-fix mode
    - 🎨 Enhanced visual output with better formatting
    - 📝 Comprehensive documentation with accurate behavior descriptions

- **1.0** (2024-11-27): Initial release
    - Scan, compare, and fix functionality
    - Audit logging
    - Interactive modes


## 🤖 Claude was here