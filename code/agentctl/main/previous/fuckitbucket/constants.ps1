# constants.ps1 - centralized configuration and URLs

$AGENTCTL_REPO_BASE = "https://raw.githubusercontent.com/username/agentctl/main"
$LOCAL_AGENT_DIR = "$env:USERPROFILE\agentctl"

# Registry Keys
$AGENTCTL_REG_ROOT    = "HKLM:\SOFTWARE\agentctl"
$AGENTCTL_REG_AUDIT   = "$AGENTCTL_REG_ROOT\Audit"

# Bootstrap Latch Key
$BOOTSTRAP_LATCH_NAME = "BootstrapComplete"

# Forced Reset Phrase
$FORCED_RESET_PHRASE  = "FORCE-RESET-BOOTSTRAP"

# Timestamp Format (UTC)
$TIMESTAMP_FMT        = "yyyyMMddHHmmss"

