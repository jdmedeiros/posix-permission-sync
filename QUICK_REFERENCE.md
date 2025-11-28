━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PERMISSION SYNC SCRIPT - QUICK REFERENCE CARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────────────────────────┐
│ BASIC WORKFLOW                                                          │
└─────────────────────────────────────────────────────────────────────────┘

System A (Reference):
  1. ./permission_sync.sh --scan
  2. scp permission_sync.sh permissions_sync_registry_*.txt user@systemB:/tmp/

System B (Target):
  3. ./permission_sync.sh --compare permissions_sync_registry_*.txt
  4. sudo ./permission_sync.sh --fix permissions_sync_registry_*.txt

┌─────────────────────────────────────────────────────────────────────────┐
│ COMMAND QUICK REFERENCE                                                 │
└─────────────────────────────────────────────────────────────────────────┘

--scan              Generate registry (interactive, creates timestamped file)
--compare FILE      Compare only (safe, read-only, no changes)
--fix FILE          Compare and fix (interactive, creates backup)
--restore FILE      Restore from backup file
--list-backups      Show all available backups
--help              Show detailed help

┌─────────────────────────────────────────────────────────────────────────┐
│ WHAT GETS CREATED                                                       │
└─────────────────────────────────────────────────────────────────────────┘

After --scan:
  ✓ permissions_sync_registry_<hostname>_<timestamp>.txt (registry file)
  ✓ scan_<timestamp>.log (scan log)
  ✓ .permission_sync_<timestamp>/ (cleaned up automatically)

After --compare:
  ✓ compare_<timestamp>.log (comparison log)
  ✓ .permission_sync_<timestamp>/ (cleaned up automatically)

After --fix:
  ✓ compare_fix_<timestamp>.log (operation log)
  ✓ .permission_sync_<timestamp>/ (PRESERVED - contains backup)
      └── backups/
          └── ownership_backup_<timestamp>.txt (versioned backup)

┌─────────────────────────────────────────────────────────────────────────┐
│ INTERACTIVE PROMPTS                                                     │
└─────────────────────────────────────────────────────────────────────────┘

During --scan:
  • Target directory? [default: /opt/starfish]
  • Registry filename? [default: auto-generated with hostname & timestamp]

During --fix:
  • Confirm target directory?
  • Continue with modifications?
  • Create backup? [recommended: yes]

During --restore:
  • Confirm restoration?

┌─────────────────────────────────────────────────────────────────────────┐
│ SAFETY FEATURES                                                         │
└─────────────────────────────────────────────────────────────────────────┘

✓ Automatic versioned backups (timestamped)
✓ Confirmation prompts before changes
✓ Complete audit trail in logs
✓ Temporary working directories
✓ Automatic cleanup (unless backups exist)
✓ Restore capability from any backup
✓ Directory validation before operations

┌─────────────────────────────────────────────────────────────────────────┐
│ COMMON TASKS                                                            │
└─────────────────────────────────────────────────────────────────────────┘

View differences only (safe):
  $ ./permission_sync.sh --compare registry.txt

Fix permissions with backup:
  $ sudo ./permission_sync.sh --fix registry.txt

List all backups:
  $ ./permission_sync.sh --list-backups

Restore from backup:
  $ sudo ./permission_sync.sh --restore .permission_sync_*/backups/ownership_backup_*.txt

Check logs:
  $ less compare_fix_<timestamp>.log

┌─────────────────────────────────────────────────────────────────────────┐
│ TROUBLESHOOTING                                                         │
└─────────────────────────────────────────────────────────────────────────┘

Permission denied:
  → Use sudo for --fix and --restore

User doesn't exist:
  → Create users/groups on target system first
  → Or review compare output to see what's needed

Need to rollback:
  → ./permission_sync.sh --list-backups
  → sudo ./permission_sync.sh --restore <backup_file>

Can't find backup:
  → Check .permission_sync_*/ directories
  → Backups only created during --fix operations

Wrong directory:
  → Script will prompt - just say 'no' and enter correct path

┌─────────────────────────────────────────────────────────────────────────┐
│ FILE NAMING CONVENTIONS                                                 │
└─────────────────────────────────────────────────────────────────────────┘

Registry files:
  permissions_sync_registry_<hostname>_YYYYMMDD_HHMMSS.txt

Backup files:
  ownership_backup_YYYYMMDD_HHMMSS.txt

Log files:
  scan_YYYYMMDD_HHMMSS.log
  compare_YYYYMMDD_HHMMSS.log
  compare_fix_YYYYMMDD_HHMMSS.log

Working directories:
  .permission_sync_YYYYMMDD_HHMMSS/

┌─────────────────────────────────────────────────────────────────────────┐
│ BEST PRACTICES                                                          │
└─────────────────────────────────────────────────────────────────────────┘

1. Always --compare before --fix
2. Always accept backup creation (default: yes)
3. Keep working directory until changes verified
4. Review logs after operations
5. Test on non-production first
6. Preserve backups for critical systems
7. Use timestamped registry files (auto-generated)

┌─────────────────────────────────────────────────────────────────────────┐
│ REQUIREMENTS                                                            │
└─────────────────────────────────────────────────────────────────────────┘

• Bash 4.0+
• Standard tools: find, stat, chown
• Read access for --scan and --compare
• Root/sudo for --fix and --restore
• Matching users/groups on target system

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For detailed help: ./permission_sync.sh --help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
