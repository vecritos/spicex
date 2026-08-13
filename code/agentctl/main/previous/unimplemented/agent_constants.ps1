# agent_constants.ps1
# Constants and enums for agentctl

$CONFIG_DIR = "$env:ProgramData\agentctl"
$LOG_DIR = Join-Path $CONFIG_DIR "logs"

# Firewall modes enum
$FIREWALL_MODES = @{
    "default" = 0
    "inspect" = 1
    "paranoid" = 2
}

# Other constants here...
