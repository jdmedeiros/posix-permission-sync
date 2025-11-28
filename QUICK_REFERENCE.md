# Permission Sync Script - Quick Reference

## Basic Workflow

### System A (Reference):
```bash
1. ./permission_sync.sh --scan
2. scp permission_sync.sh permissions_sync_registry_*.txt user@systemB:/tmp/
```

### System B (Target):
```bash
3. ./permission_sync.sh --compare permissions_sync_registry_*.txt
4. sudo ./permission_sync.sh --fix permissions_sync_registry_*.txt
```

---

## Command Quick Reference

| Command | Description |
|---------|-------------|
| `--scan` | Generate registry (interactive, creates timestamped file) |
| `--compare FILE` | Compare only (safe, read-only, no changes) |
| `--fix FILE` | Compare and fix (interactive, creates backup) |
| `--restore FILE` | Restore from backup file |
| `--list-backups` | Show all available backups |
| `--help` | Show detailed help |

---

## What Gets Created

### After `--scan`:
- ✓ `permissions_sync_registry_<hostname>_<timestamp>.txt` (registry file)
- ✓ `scan_<timestamp>.log` (scan log)
- ✓ `.permission_sync_<timestamp>/` (cleaned up automatically)

### After `--compare`:
- ✓ `compare_<timestamp>.log` (comparison log)
- ✓ `.permission_sync_<timestamp>/` (cleaned up automatically)

### After `--fix`:
- ✓ `compare_fix_<timestamp>.log` (operation log)
- ✓ `.permission_sync_<timestamp>/` (**PRESERVED** - contains backup)
  - `backups/ownership_backup_<timestamp>.txt` (versioned backup)

---

## Interactive Prompts

### During `--scan`:
- Target directory? **[default: /opt/starfish]**
- Registry filename? **[default: auto-generated with hostname & timestamp]**

### During `--fix`:
- Confirm target directory?
- Continue with modifications?
- Create backup? **[recommended: yes]**

### During `--restore`:
- Confirm restoration?

---

## Safety Features

- ✓ Automatic versioned backups (timestamped)
- ✓ Confirmation prompts before changes
- ✓ Complete audit trail in logs
- ✓ Temporary working directories
- ✓ Automatic cleanup (unless backups exist)
- ✓ Restore capability from any backup
- ✓ Directory validation before operations

---

## Common Tasks

### View differences only (safe):
```bash
./permission_sync.sh --compare registry.txt
```

### Fix permissions with backup:
```bash
sudo ./permission_sync.sh --fix registry.txt
```

### List all backups:
```bash
./permission_sync.sh --list-backups
```

### Restore from backup:
```bash
sudo ./permission_sync.sh --restore .permission_sync_*/backups/ownership_backup_*.txt
```

### Check logs:
```bash
less compare_fix_<timestamp>.log
```

---

## Troubleshooting

### Permission denied
**Solution:** Use sudo for `--fix` and `--restore`
```bash
sudo ./permission_sync.sh --fix registry.txt
```

### User doesn't exist
**Solution:** Create users/groups on target system first, or review compare output
```bash
sudo useradd appuser
sudo groupadd appgroup
```

### Need to rollback
**Solution:** List and restore from backup
```bash
./permission_sync.sh --list-backups
sudo ./permission_sync.sh --restore <backup_file>
```

### Can't find backup
**Solution:** Check `.permission_sync_*/` directories (backups only created during `--fix`)

### Wrong directory
**Solution:** Script will prompt - just say 'no' and enter correct path

---

## File Naming Conventions

| Type | Format |
|------|--------|
| Registry files | `permissions_sync_registry_<hostname>_YYYYMMDD_HHMMSS.txt` |
| Backup files | `ownership_backup_YYYYMMDD_HHMMSS.txt` |
| Scan logs | `scan_YYYYMMDD_HHMMSS.log` |
| Compare logs | `compare_YYYYMMDD_HHMMSS.log` |
| Fix logs | `compare_fix_YYYYMMDD_HHMMSS.log` |
| Working dirs | `.permission_sync_YYYYMMDD_HHMMSS/` |

---

## Best Practices

1. **Always `--compare` before `--fix`**
2. **Always accept backup creation** (default: yes)
3. **Keep working directory until changes verified**
4. **Review logs after operations**
5. **Test on non-production first**
6. **Preserve backups for critical systems**
7. **Use timestamped registry files** (auto-generated)

---

## Requirements

- Bash 4.0+
- Standard tools: `find`, `stat`, `chown`
- Read access for `--scan` and `--compare`
- Root/sudo for `--fix` and `--restore`
- Matching users/groups on target system

---

## Example Session

```bash
# On System A - Generate registry
$ ./permission_sync.sh --scan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target Directory Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Default directory: /opt/starfish

Use default directory? (yes/no) [yes]: yes
✓ Using directory: /opt/starfish

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Registry File Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Suggested name: permissions_sync_registry_server1_20241127_103045.txt

Use suggested name? (yes/no) [yes]: yes
✓ Registry will be saved as: permissions_sync_registry_server1_20241127_103045.txt

✓ Scan completed successfully
  Files scanned: 156
  Registry saved: ./permissions_sync_registry_server1_20241127_103045.txt
```

```bash
# Transfer to System B
$ scp permission_sync.sh permissions_sync_registry_*.txt user@server2:/tmp/
```

```bash
# On System B - Compare first (safe)
$ cd /tmp
$ ./permission_sync.sh --compare permissions_sync_registry_server1_20241127_103045.txt

✗ DIFFERENT: /opt/starfish/config
  Expected: appuser:appgroup (644)
  Current:  root:root (644)

Summary: 156 files, 5 different, 0 missing
```

```bash
# On System B - Fix with backup
$ sudo ./permission_sync.sh --fix permissions_sync_registry_server1_20241127_103045.txt

⚠ WARNING: Permission Modification Mode
Continue? (yes/no): yes

Create backup before making changes? (yes/no) [yes]: yes

✓ Backup created successfully
  Location: .permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt

✗ DIFFERENT: /opt/starfish/config
  Expected: appuser:appgroup (644)
  Current:  root:root (644)
  ✓ FIXED ownership

Successfully fixed: 5
Failed to fix: 0

To restore from backup, run:
  ./permission_sync.sh --restore ".permission_sync_20241127_104523/backups/ownership_backup_20241127_104523.txt"
```

---

**For detailed help:** `./permission_sync.sh --help`


## 🤖 Claude was here