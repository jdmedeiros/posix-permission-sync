#!/bin/bash

################################################################################
# Permission Comparison and Sync Script
# Purpose: Compare and optionally sync user:group ownership between two systems
# Usage:
#   - System A: ./permission_sync.sh --scan
#   - System B: ./permission_sync.sh --compare <registry_file> [--fix]
################################################################################

set -euo pipefail

# Default Configuration
DEFAULT_TARGET_DIR="/opt/starfish"
DEFAULT_REGISTRY_NAME="permissions_sync_registry"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Working directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/.permission_sync_${TIMESTAMP}"
BACKUP_DIR="${WORK_DIR}/backups"
LOG_FILE="${WORK_DIR}/permission_sync_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
TARGET_DIR=""
REGISTRY_FILE=""
CLEANUP_ON_EXIT=true

# Sync options (what to sync)
SYNC_USER=true
SYNC_GROUP=true
SYNC_PERMS=true

################################################################################
# Cleanup and Setup Functions
################################################################################

cleanup() {
    if [[ "$CLEANUP_ON_EXIT" = true ]] && [[ -d "$WORK_DIR" ]]; then
        echo -e "\n${CYAN}Cleaning up temporary directory...${NC}"
        rm -rf "$WORK_DIR"
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT INT TERM

setup_work_directory() {
    mkdir -p "$WORK_DIR"
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}✓ Created working directory: $WORK_DIR${NC}"
    echo -e "${GREEN}✓ Created backup directory: $BACKUP_DIR${NC}"
    log "Working directory created: $WORK_DIR"
    log "Backup directory created: $BACKUP_DIR"
}

################################################################################
# Interactive Configuration Functions
################################################################################

show_sync_config() {
    echo -e "${CYAN}Sync Configuration:${NC}"
    echo -n "  Syncing: "
    local parts=()
    [[ "$SYNC_USER" = true ]] && parts+=("user")
    [[ "$SYNC_GROUP" = true ]] && parts+=("group")
    [[ "$SYNC_PERMS" = true ]] && parts+=("permissions")

    if [[ ${#parts[@]} -eq 0 ]]; then
        echo -e "${RED}NOTHING (all disabled)${NC}"
    else
        echo -e "${YELLOW}$(IFS=', '; echo "${parts[*]}")${NC}"
    fi
}

prompt_target_directory() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Target Directory Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Default directory: ${YELLOW}$DEFAULT_TARGET_DIR${NC}"
    echo ""
    read -p "Use default directory? (yes/no) [yes]: " use_default
    use_default=${use_default:-yes}

    if [[ "$use_default" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        TARGET_DIR="$DEFAULT_TARGET_DIR"
    else
        read -p "Enter target directory path: " TARGET_DIR
        TARGET_DIR="${TARGET_DIR%/}" # Remove trailing slash
    fi

    # Validate directory exists
    if [[ ! -d "$TARGET_DIR" ]]; then
        echo -e "${RED}✗ Error: Directory '$TARGET_DIR' does not exist${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}✓ Using directory: $TARGET_DIR${NC}\n"
    log "Target directory set to: $TARGET_DIR"
}

prompt_registry_name() {
    local mode="$1" # 'scan' or 'compare'

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Registry File Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ "$mode" = "scan" ]]; then
        local suggested_name="${DEFAULT_REGISTRY_NAME}_$(hostname)_${TIMESTAMP}.txt"
        echo -e "Suggested name: ${YELLOW}$suggested_name${NC}"
        echo ""
        read -p "Use suggested name? (yes/no) [yes]: " use_default
        use_default=${use_default:-yes}

        if [[ "$use_default" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            REGISTRY_FILE="$suggested_name"
        else
            read -p "Enter registry filename: " REGISTRY_FILE
        fi

        echo -e "${GREEN}✓ Registry will be saved as: $REGISTRY_FILE${NC}\n"
        log "Registry filename set to: $REGISTRY_FILE"
    fi
}

################################################################################
# Backup Functions
################################################################################

create_backup() {
    local backup_file="${BACKUP_DIR}/ownership_backup_${TIMESTAMP}.txt"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Creating Backup${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    log "Creating backup of current permissions"

    echo "# Ownership backup created on $(hostname) at $(date)" > "$backup_file"
    echo "# Target directory: $TARGET_DIR" >> "$backup_file"
    echo "# Backup can be used to restore permissions" >> "$backup_file"
    echo "# Format: filepath|user|group|permissions" >> "$backup_file"
    echo "#---" >> "$backup_file"

    find "$TARGET_DIR" -printf "%p|%u|%g|%m\n" 2>/dev/null | sort >> "$backup_file"

    if [[ $? -eq 0 ]]; then
        local file_count=$(grep -cv '^#' "$backup_file")
        echo -e "${GREEN}✓ Backup created successfully${NC}"
        echo -e "  Location: ${YELLOW}$backup_file${NC}"
        echo -e "  Files backed up: ${YELLOW}$file_count${NC}"
        log "Backup created: $backup_file ($file_count files)"
        echo "$backup_file"
    else
        echo -e "${RED}✗ Failed to create backup${NC}" >&2
        log "ERROR: Failed to create backup"
        return 1
    fi
}

list_backups() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Available Backups${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "No backups found."
        return
    fi

    local idx=1
    for backup in "$BACKUP_DIR"/ownership_backup_*.txt; do
        if [[ -f "$backup" ]]; then
            local size=$(du -h "$backup" | cut -f1)
            local timestamp=$(basename "$backup" | sed 's/ownership_backup_\(.*\)\.txt/\1/')
            echo -e "${YELLOW}[$idx]${NC} $timestamp (Size: $size)"
            echo "     $backup"
            ((idx++))
        fi
    done
}

restore_from_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗ Backup file not found: $backup_file${NC}" >&2
        return 1
    fi

    # Extract target directory from backup header
    local backup_target_dir=$(grep "^# Target directory:" "$backup_file" | cut -d: -f2- | xargs)

    echo -e "${YELLOW}⚠ WARNING: This will restore ownership and permissions from backup${NC}"
    echo -e "Backup file: $backup_file"
    if [[ -n "$backup_target_dir" ]]; then
        echo -e "Target directory: $backup_target_dir"
    fi
    echo ""
    read -p "Are you sure you want to restore? (yes/no): " confirm

    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Restore cancelled."
        return 1
    fi

    echo -e "\n${CYAN}Restoring from backup...${NC}"
    log "Restoring permissions from backup: $backup_file"
    if [[ -n "$backup_target_dir" ]]; then
        log "Target directory from backup: $backup_target_dir"
    fi

    local restored=0
    local failed=0

    while IFS='|' read -r filepath user group perms; do
        [[ "$filepath" =~ ^#.* ]] && continue
        [[ -z "$filepath" ]] && continue

        if [[ -e "$filepath" ]]; then
            local restore_success=true

            # Restore ownership (user and/or group)
            if [[ "$SYNC_USER" = true ]] || [[ "$SYNC_GROUP" = true ]]; then
                local new_owner=""

                if [[ "$SYNC_USER" = true ]] && [[ "$SYNC_GROUP" = true ]]; then
                    new_owner="$user:$group"
                elif [[ "$SYNC_USER" = true ]]; then
                    new_owner="$user"
                elif [[ "$SYNC_GROUP" = true ]]; then
                    new_owner=":$group"
                fi

                if [[ -n "$new_owner" ]] && ! chown "$new_owner" "$filepath" 2>/dev/null; then
                    restore_success=false
                fi
            fi

            # Restore permissions
            if [[ "$SYNC_PERMS" = true ]] && ! chmod "$perms" "$filepath" 2>/dev/null; then
                restore_success=false
            fi

            if [[ "$restore_success" = true ]]; then
                ((restored++))
                log_action "RESTORED" "$filepath" "unknown" "$user:$group ($perms)"
            else
                ((failed++))
                log "FAILED: Could not restore $filepath"
            fi
        fi
    done < <(grep -v '^#' "$backup_file")

    echo -e "${GREEN}✓ Restore complete${NC}"
    echo "  Successfully restored: $restored"
    echo "  Failed: $failed"
    log "Restore completed: $restored successful, $failed failed"
}

################################################################################
# Logging Functions
################################################################################

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log_action() {
    local action="$1"
    local file="$2"
    local old_perm="$3"
    local new_perm="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ACTION: $action | FILE: $file | OLD: $old_perm | NEW: $new_perm" | tee -a "$LOG_FILE"
}

################################################################################
# Scan Function - Generate permission snapshot
################################################################################

scan_permissions() {
    setup_work_directory
    prompt_target_directory
    prompt_registry_name "scan"

    local output_file="${SCRIPT_DIR}/${REGISTRY_FILE}"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Scanning Permissions${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "System: ${YELLOW}$(hostname)${NC}"
    echo -e "Directory: ${YELLOW}$TARGET_DIR${NC}"
    echo -e "Output file: ${YELLOW}$output_file${NC}"
    echo ""

    log "Starting permission scan"
    log "Target directory: $TARGET_DIR"

    {
        echo "# Permission scan generated on $(hostname) at $(date)"
        echo "# Target directory: $TARGET_DIR"
        echo "# Format: filepath|user|group|permissions"
        echo "#---"
        find "$TARGET_DIR" -printf "%p|%u|%g|%m\n" 2>/dev/null | sort
    } > "$output_file"

    if [[ $? -eq 0 ]]; then
        local file_count=$(grep -cv '^#' "$output_file")
        echo -e "${GREEN}✓ Scan completed successfully${NC}"
        echo -e "  Files scanned: ${YELLOW}$file_count${NC}"
        echo -e "  Registry saved: ${YELLOW}$output_file${NC}"
        log "Scan completed: $file_count files"

        # Copy log to final location
        cp "$LOG_FILE" "${SCRIPT_DIR}/scan_${TIMESTAMP}.log"
        echo -e "  Log saved: ${YELLOW}${SCRIPT_DIR}/scan_${TIMESTAMP}.log${NC}"
        echo -e "\n${GREEN}✓ Ready to transfer to other system${NC}"
    else
        echo -e "${RED}✗ Scan failed${NC}" >&2
        log "ERROR: Scan failed"
        exit 1
    fi
}

################################################################################
# Compare Function - Compare with reference and optionally fix
################################################################################

compare_and_fix() {
    local reference_file="$1"
    local fix_mode="${2:-false}"

    setup_work_directory

    if [[ ! -f "$reference_file" ]]; then
        echo -e "${RED}Error: Reference file $reference_file not found${NC}" >&2
        exit 1
    fi

    # Extract target directory from reference file
    TARGET_DIR=$(grep "^# Target directory:" "$reference_file" | cut -d: -f2- | xargs)

    if [[ -z "$TARGET_DIR" ]]; then
        echo -e "${YELLOW}⚠ Could not detect target directory from registry file${NC}"
        prompt_target_directory
    else
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Target Directory Configuration${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Detected from registry: ${YELLOW}$TARGET_DIR${NC}"
        echo ""
        read -p "Use this directory? (yes/no) [yes]: " use_detected
        use_detected=${use_detected:-yes}

        if [[ ! "$use_detected" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            prompt_target_directory
        else
            if [[ ! -d "$TARGET_DIR" ]]; then
                echo -e "${RED}✗ Error: Directory '$TARGET_DIR' does not exist${NC}" >&2
                exit 1
            fi
            echo -e "${GREEN}✓ Using directory: $TARGET_DIR${NC}\n"
        fi
    fi

    # Initialize counters
    local total_files=0
    local different_files=0
    local fixed_files=0
    local failed_fixes=0
    local missing_files=0
    local backup_file=""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Permission Comparison Report${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "System: $(hostname)"
    echo "Reference: $reference_file"
    echo "Target Directory: $TARGET_DIR"
    show_sync_config
    echo "Mode: $([ "$fix_mode" = true ] && echo 'FIX' || echo 'COMPARE ONLY')"
    echo "Started: $(date)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    log "Starting permission comparison"
    log "Reference file: $reference_file"
    log "Fix mode: $fix_mode"

    # Create backup before making any changes
    if [[ "$fix_mode" = true ]]; then
        echo ""
        read -p "Create backup before making changes? (yes/no) [yes]: " create_backup_answer
        create_backup_answer=${create_backup_answer:-yes}

        if [[ "$create_backup_answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            backup_file=$(create_backup)
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}✗ Backup failed. Aborting.${NC}" >&2
                exit 1
            fi
            echo ""
        else
            echo -e "${YELLOW}⚠ Proceeding without backup${NC}\n"
            log "WARNING: User declined backup creation"
        fi
    fi

    # Read reference file and compare
    while IFS='|' read -r filepath user group perms; do
        # Skip comments and header lines
        [[ "$filepath" =~ ^#.* ]] && continue
        [[ -z "$filepath" ]] && continue

        ((total_files++))

        # Check if file exists on this system
        if [[ ! -e "$filepath" ]]; then
            echo -e "${YELLOW}⚠ MISSING: $filepath${NC}"
            log "MISSING: File does not exist on this system: $filepath"
            ((missing_files++))
            continue
        fi

        # Get current ownership and permissions
        current_user=$(stat -c '%U' "$filepath" 2>/dev/null)
        current_group=$(stat -c '%G' "$filepath" 2>/dev/null)
        current_perms=$(stat -c '%a' "$filepath" 2>/dev/null)

        # Check if anything is different (based on what we're syncing)
        user_different=false
        group_different=false
        perms_different=false

        if [[ "$SYNC_USER" = true ]] && [[ "$current_user" != "$user" ]]; then
            user_different=true
        fi

        if [[ "$SYNC_GROUP" = true ]] && [[ "$current_group" != "$group" ]]; then
            group_different=true
        fi

        if [[ "$SYNC_PERMS" = true ]] && [[ "$current_perms" != "$perms" ]]; then
            perms_different=true
        fi

        # Report and fix differences
        if [[ "$user_different" = true ]] || [[ "$group_different" = true ]] || [[ "$perms_different" = true ]]; then
            ((different_files++))
            echo -e "${RED}✗ DIFFERENT: $filepath${NC}"
            echo "  Expected: $user:$group ($perms)"
            echo "  Current:  $current_user:$current_group ($current_perms)"

            if [[ "$fix_mode" = true ]]; then
                local fix_success=true

                # Fix user and/or group if different
                if [[ "$user_different" = true ]] || [[ "$group_different" = true ]]; then
                    local new_owner=""

                    # Determine what to change
                    if [[ "$SYNC_USER" = true ]] && [[ "$SYNC_GROUP" = true ]]; then
                        new_owner="$user:$group"
                    elif [[ "$SYNC_USER" = true ]]; then
                        new_owner="$user"
                    elif [[ "$SYNC_GROUP" = true ]]; then
                        new_owner=":$group"
                    fi

                    if [[ -n "$new_owner" ]]; then
                        if chown "$new_owner" "$filepath" 2>/dev/null; then
                            local change_desc=""
                            if [[ "$user_different" = true ]]; then
                                change_desc="user"
                            fi
                            if [[ "$group_different" = true ]]; then
                                if [[ -n "$change_desc" ]]; then
                                    change_desc="$change_desc and group"
                                else
                                    change_desc="group"
                                fi
                            fi
                            echo -e "${GREEN}  ✓ FIXED $change_desc${NC}"
                            log_action "FIXED_OWNERSHIP" "$filepath" "$current_user:$current_group" "$user:$group"
                        else
                            echo -e "${RED}  ✗ FAILED to fix ownership (may need root/sudo)${NC}"
                            log "FAILED: Could not change ownership of $filepath"
                            fix_success=false
                        fi
                    fi
                fi

                # Fix permissions if different
                if [[ "$perms_different" = true ]]; then
                    if chmod "$perms" "$filepath" 2>/dev/null; then
                        echo -e "${GREEN}  ✓ FIXED permissions${NC}"
                        log_action "FIXED_PERMISSIONS" "$filepath" "$current_perms" "$perms"
                    else
                        echo -e "${RED}  ✗ FAILED to fix permissions (may need root/sudo)${NC}"
                        log "FAILED: Could not change permissions of $filepath"
                        fix_success=false
                    fi
                fi

                if [[ "$fix_success" = true ]]; then
                    ((fixed_files++))
                else
                    ((failed_fixes++))
                fi
            fi
        fi
    done < <(grep -v '^#' "$reference_file")

    # Summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Total files in reference: $total_files"
    echo "Files with differences: $different_files"
    echo "Missing files: $missing_files"

    if [[ "$fix_mode" = true ]]; then
        echo "Successfully fixed: $fixed_files"
        echo "Failed to fix: $failed_fixes"

        if [[ -n "$backup_file" ]]; then
            echo ""
            echo -e "${GREEN}Backup available at:${NC}"
            echo -e "  ${YELLOW}$backup_file${NC}"
            echo -e "\nTo restore from backup, run:"
            echo -e "  ${CYAN}$0 --restore \"$backup_file\"${NC}"
        fi

        # Save final log
        local final_log="${SCRIPT_DIR}/compare_fix_${TIMESTAMP}.log"
        cp "$LOG_FILE" "$final_log"
        echo -e "\n${GREEN}Log saved to: $final_log${NC}"

        # Don't cleanup if we have backups
        if [[ -n "$backup_file" ]]; then
            CLEANUP_ON_EXIT=false
            echo -e "${CYAN}Working directory preserved: $WORK_DIR${NC}"
        fi
    else
        echo -e "\n${YELLOW}Run with --fix flag to apply changes${NC}"

        # Save comparison log
        local final_log="${SCRIPT_DIR}/compare_${TIMESTAMP}.log"
        cp "$LOG_FILE" "$final_log"
        echo -e "${GREEN}Log saved to: $final_log${NC}"
    fi
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

################################################################################
# Interactive Fix Function
################################################################################

interactive_fix() {
    local reference_file="$1"

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠ WARNING: Permission Modification Mode${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "This will compare and potentially modify file ownership and permissions."
    echo "A backup will be created before making any changes."
    echo ""

    read -p "Continue? (yes/no): " response
    if [[ ! "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    compare_and_fix "$reference_file" true
}

################################################################################
# Main
################################################################################

show_usage() {
    cat << EOF
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${CYAN}Permission Sync Script - Interactive Mode${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${GREEN}USAGE:${NC}
    $0 [OPTIONS] [SYNC_FLAGS]

${GREEN}OPTIONS:${NC}
    ${YELLOW}--scan${NC}              Generate permission snapshot (interactive)
                        - Prompts for target directory (default: /opt/starfish)
                        - Prompts for registry filename
                        - Creates timestamped registry file

    ${YELLOW}--compare FILE${NC}      Compare current system with reference FILE
                        - Shows differences only
                        - No modifications made

    ${YELLOW}--fix FILE${NC}          Compare and fix permissions interactively
                        - Prompts for confirmation
                        - Creates versioned backup before changes
                        - Full audit trail

    ${YELLOW}--restore FILE${NC}      Restore permissions from a backup file
                        - Use backups created during --fix operations

    ${YELLOW}--list-backups${NC}      List all available backups in working directory

    ${YELLOW}--help${NC}              Show this help message

${GREEN}SYNC FLAGS (optional - control what to sync):${NC}
    ${YELLOW}--user-only${NC}         Sync only user ownership
    ${YELLOW}--group-only${NC}        Sync only group ownership
    ${YELLOW}--perms-only${NC}        Sync only permission mode bits (rwx/755/644)
    ${YELLOW}--no-user${NC}           Skip user (sync group and permissions)
    ${YELLOW}--no-group${NC}          Skip group (sync user and permissions)
    ${YELLOW}--no-perms${NC}          Skip permissions (sync user and group only)

    ${CYAN}Default: sync everything (user, group, and permissions)${NC}
    ${CYAN}Flags can be combined: --user-only with --fix syncs only user${NC}

${GREEN}EXAMPLES:${NC}
    ${CYAN}# Step 1: On System A - Generate reference${NC}
    $0 --scan

    ${CYAN}# Step 2: Transfer files to System B${NC}
    scp permission_sync.sh permissions_sync_registry_*.txt user@systemB:/tmp/

    ${CYAN}# Step 3: On System B - Compare only (safe)${NC}
    cd /tmp
    $0 --compare permissions_sync_registry_systemA_20241127_103045.txt

    ${CYAN}# Step 4: On System B - Fix everything${NC}
    sudo $0 --fix permissions_sync_registry_systemA_20241127_103045.txt

    ${CYAN}# Fix only user ownership${NC}
    sudo $0 --fix --user-only permissions_sync_registry_systemA_20241127_103045.txt

    ${CYAN}# Fix only permissions (mode bits)${NC}
    sudo $0 --fix --perms-only permissions_sync_registry_systemA_20241127_103045.txt

    ${CYAN}# Fix user and group, but not permissions${NC}
    sudo $0 --fix --no-perms permissions_sync_registry_systemA_20241127_103045.txt

    ${CYAN}# Restore only group ownership from backup${NC}
    sudo $0 --restore --group-only .permission_sync_*/backups/ownership_backup_*.txt

    ${CYAN}# List available backups${NC}
    $0 --list-backups

${GREEN}SAFETY FEATURES:${NC}
    ✓ Interactive prompts for directory and filename
    ✓ Automatic versioned backups (timestamped)
    ✓ Temporary working directory for all operations
    ✓ Automatic cleanup (unless backups exist)
    ✓ Full audit trail in log files
    ✓ Confirmation prompts before modifications

${GREEN}WORKING DIRECTORIES:${NC}
    Registry files:     ${YELLOW}./permissions_sync_registry_<host>_<timestamp>.txt${NC}
    Working directory:  ${YELLOW}./.permission_sync_<timestamp>/${NC}
    Backups:           ${YELLOW}./.permission_sync_<timestamp>/backups/${NC}
    Logs:              ${YELLOW}./.permission_sync_<timestamp>/*.log${NC}

${GREEN}NOTES:${NC}
    - Fixing permissions typically requires root/sudo access
    - Backups are automatically versioned with timestamps
    - Working directories are preserved when backups exist
    - All operations create detailed audit logs
    - Registry filename suggestions include hostname and timestamp

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
EOF
}

# Parse arguments
COMMAND=""
COMMAND_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        # Sync flags (can appear anywhere)
        --user-only)
            SYNC_USER=true
            SYNC_GROUP=false
            SYNC_PERMS=false
            shift
            ;;
        --group-only)
            SYNC_USER=false
            SYNC_GROUP=true
            SYNC_PERMS=false
            shift
            ;;
        --perms-only)
            SYNC_USER=false
            SYNC_GROUP=false
            SYNC_PERMS=true
            shift
            ;;
        --no-user)
            SYNC_USER=false
            shift
            ;;
        --no-group)
            SYNC_GROUP=false
            shift
            ;;
        --no-perms)
            SYNC_PERMS=false
            shift
            ;;
        # Main commands that don't take arguments
        --scan|--list-backups|--help)
            COMMAND="$1"
            shift
            ;;
        # Main commands that require a file argument
        --compare|--fix|--restore)
            COMMAND="$1"
            shift
            ;;
        # Anything that doesn't start with -- is likely a file argument
        *)
            if [[ "$COMMAND" =~ ^--(compare|fix|restore)$ ]] && [[ -z "$COMMAND_ARG" ]] && [[ ! "$1" =~ ^-- ]]; then
                COMMAND_ARG="$1"
                shift
            else
                echo -e "${RED}Error: Unknown or unexpected argument '$1'${NC}" >&2
                show_usage
                exit 1
            fi
            ;;
    esac
done

# Default to help if no command given
if [[ -z "$COMMAND" ]]; then
    COMMAND="--help"
fi

# Execute command
case "$COMMAND" in
    --scan)
        # Validate at least one sync option is enabled
        if [[ "$SYNC_USER" = false ]] && [[ "$SYNC_GROUP" = false ]] && [[ "$SYNC_PERMS" = false ]]; then
            echo -e "${RED}Error: At least one sync option must be enabled${NC}" >&2
            echo -e "${YELLOW}You've disabled user, group, AND permissions - nothing to sync!${NC}" >&2
            exit 1
        fi
        scan_permissions
        ;;
    --compare)
        # Validate at least one sync option is enabled
        if [[ "$SYNC_USER" = false ]] && [[ "$SYNC_GROUP" = false ]] && [[ "$SYNC_PERMS" = false ]]; then
            echo -e "${RED}Error: At least one sync option must be enabled${NC}" >&2
            echo -e "${YELLOW}You've disabled user, group, AND permissions - nothing to sync!${NC}" >&2
            exit 1
        fi
        if [[ -z "$COMMAND_ARG" ]]; then
            echo -e "${RED}Error: --compare requires a reference file${NC}" >&2
            show_usage
            exit 1
        fi
        compare_and_fix "$COMMAND_ARG" false
        ;;
    --fix)
        # Validate at least one sync option is enabled
        if [[ "$SYNC_USER" = false ]] && [[ "$SYNC_GROUP" = false ]] && [[ "$SYNC_PERMS" = false ]]; then
            echo -e "${RED}Error: At least one sync option must be enabled${NC}" >&2
            echo -e "${YELLOW}You've disabled user, group, AND permissions - nothing to sync!${NC}" >&2
            exit 1
        fi
        if [[ -z "$COMMAND_ARG" ]]; then
            echo -e "${RED}Error: --fix requires a reference file${NC}" >&2
            show_usage
            exit 1
        fi
        interactive_fix "$COMMAND_ARG"
        ;;
    --restore)
        # Validate at least one sync option is enabled
        if [[ "$SYNC_USER" = false ]] && [[ "$SYNC_GROUP" = false ]] && [[ "$SYNC_PERMS" = false ]]; then
            echo -e "${RED}Error: At least one sync option must be enabled${NC}" >&2
            echo -e "${YELLOW}You've disabled user, group, AND permissions - nothing to sync!${NC}" >&2
            exit 1
        fi
        if [[ -z "$COMMAND_ARG" ]]; then
            echo -e "${RED}Error: --restore requires a backup file${NC}" >&2
            show_usage
            exit 1
        fi
        setup_work_directory
        restore_from_backup "$COMMAND_ARG"
        ;;
    --list-backups)
        # Look for any working directories with backups
        echo -e "${CYAN}Searching for backup directories...${NC}\n"
        found_backups=false

        # Enable nullglob so pattern doesn't show if nothing matches
        shopt -s nullglob
        for work_dir in .permission_sync_*/backups; do
            if [[ -d "$work_dir" ]]; then
                BACKUP_DIR="$work_dir"
                list_backups
                found_backups=true
            fi
        done
        shopt -u nullglob

        if [[ "$found_backups" = false ]]; then
            echo "No backup directories found."
        fi
        CLEANUP_ON_EXIT=false
        ;;
    --help)
        show_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command $COMMAND${NC}" >&2
        show_usage
        exit 1
        ;;
esac

## 🤖 Claude was here