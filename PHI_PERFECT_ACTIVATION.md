# PHI Perfect Activation System
## Dual-Mode Operation: Autonomous 24/7 & Interactive Development

**Version:** 2.0  
**Date:** March 10, 2026  
**Sovereignty Level:** 9/9 Maximum Power

---

## 🎯 Overview

The PHI Perfect Activation System provides seamless dual-mode operation:

1. **Autonomous Mode (24/7 NHITL)** - No Human In The Loop continuous operation
2. **Interactive Mode (VS Code)** - Development workflow with debugging and hot-reload

### Key Features

- ✅ **Perfect Dev Container** - Pre-configured development environment
- ✅ **Intelligent Mode Detection** - Automatic mode awareness and switching
- ✅ **Graceful Startup/Shutdown** - Clean state management for both modes
- ✅ **VS Code Lifecycle Hooks** - Automatic setup on container lifecycle events
- ✅ **Unified Command Interface** - Single `phi` command for all operations
- ✅ **Telemetry & Logging** - Comprehensive system monitoring
- ✅ **State Preservation** - Quick restart capability

---

## 🚀 Quick Start

### Method 1: Unified Command (Recommended)

```bash
# Show system status
cd /workspaces/dominion-os-demo-build/scripts
./phi status

# Start in interactive mode (for development)
./phi start-interactive

# Start in autonomous mode (for 24/7 operation)
./phi start-autonomous

# Stop services
./phi stop

# Get help
./phi help
```

### Method 2: Direct Scripts

```bash
cd /workspaces/dominion-os-demo-build/scripts

# Interactive Mode (VS Code Development)
bash phi_interactive_startup.sh      # Start
bash phi_interactive_shutdown.sh     # Stop

# Autonomous Mode (24/7 NHITL)
bash phi_perfect_autonomous_startup.sh      # Start
bash phi_perfect_autonomous_shutdown.sh     # Stop
```

---

## 📋 Two Operating Modes

### 🤖 Autonomous Mode (24/7 NHITL)

**When to use:**
- Running services without VS Code
- 24/7 continuous operation
- Maximum sovereignty (9/9 power)
- Background execution
- Production-like environment

**Features:**
- Sovereign keepalive process monitors all services
- Automatic restart on failure
- No user interaction required
- Full telemetry and logging
- Cost optimization engine active
- Background completion monitoring

**Startup:**
```bash
bash scripts/phi_perfect_autonomous_startup.sh
```

**What happens:**
1. Sets autonomous mode flag
2. Starts all core services (ports 5000, 5001, 8080, 8081)
3. Activates sovereign keepalive (NHITL controller)
4. Launches background services (Channel Connect, Google Workspace)
5. Enables continuous monitoring

**Shutdown:**
```bash
bash scripts/phi_perfect_autonomous_shutdown.sh
```

**What happens:**
1. Signals NHITL loop to stop
2. Gracefully stops sovereign processes
3. Stops background services
4. Stops core web services
5. Archives logs and telemetry
6. Clears autonomous mode flag

---

### 👤 Interactive Mode (VS Code Development)

**When to use:**
- Active development in VS Code
- Debugging and testing
- Hot-reload during coding
- User wants status updates and commands
- Code changes and immediate feedback

**Features:**
- Flask debug mode enabled
- Hot-reload on file changes
- Console output for debugging
- Quick restart capability
- Manual control over background services
- Workspace state preservation

**Startup:**
```bash
bash scripts/phi_interactive_startup.sh
```

**What happens:**
1. Removes autonomous mode flag
2. Activates development environment
3. Starts services in debug mode
4. Enables hot-reload
5. Provides console access
6. Optional background services

**Shutdown:**
```bash
bash scripts/phi_interactive_shutdown.sh
```

**What happens:**
1. Gracefully stops all services
2. Saves workspace state
3. Preserves quick-restart capability
4. Keeps development environment ready

---

## 🔧 Dev Container Configuration

The perfect dev container is automatically configured with:

### Features Included
- Docker-in-Docker
- GitHub CLI
- Node.js LTS
- Python 3.11
- Git latest

### Extensions Auto-Installed
- GitHub Copilot & Copilot Chat
- Python (Pylance, debugpy)
- Docker tools
- GitLens
- YAML support
- And 20+ more productivity extensions

### Lifecycle Hooks

**Post-Create** (`.devcontainer/scripts/post-create.sh`)
- Runs once after container creation
- Sets up Python virtual environment
- Installs dependencies
- Creates directory structure
- Sets permissions

**Post-Start** (`.devcontainer/scripts/post-start.sh`)
- Runs every time container starts
- Checks for autonomous mode
- Restarts sovereign processes if needed
- Cleans stale PID files
- Updates telemetry

**Post-Attach** (`.devcontainer/scripts/post-attach.sh`)
- Runs when VS Code attaches
- Activates virtual environment
- Displays system status
- Shows quick commands
- Welcomes user

---

## 🎛️ Unified Command Interface

The `phi` command is your unified control center:

### Status Commands

```bash
./phi status          # Show complete system status
./phi telemetry       # View telemetry data
./phi logs            # View recent logs
```

### Control Commands

```bash
./phi start-autonomous    # Start 24/7 mode
./phi start-interactive   # Start dev mode
./phi stop                # Stop current mode
./phi emergency-stop      # Force stop all processes
./phi switch-mode         # Interactive mode switcher
```

### Help

```bash
./phi help
./phi --help
./phi h
```

---

## 📊 System Status Display

The status display shows:

### Operational Mode
- Current mode (Autonomous/Interactive/Stopped)
- Sovereignty level
- User activity status

### Services Status
- Active service count (X/4)
- Port assignments
- Process IDs
- Service health

### Sovereign Processes
- Keepalive status
- Background monitors
- Autonomous controllers

### System Resources
- Disk usage
- Memory usage
- Available capacity

---

## 🔄 Mode Switching

### Autonomous → Interactive

```bash
cd scripts
bash phi_perfect_autonomous_shutdown.sh
bash phi_interactive_startup.sh
```

Or use unified command:
```bash
./phi switch-mode
# Select option 2 (Interactive)
```

### Interactive → Autonomous

```bash
cd scripts
bash phi_interactive_shutdown.sh
bash phi_perfect_autonomous_startup.sh
```

Or use unified command:
```bash
./phi switch-mode
# Select option 1 (Autonomous)
```

---

## 📁 Directory Structure

```
/workspaces/dominion-os-demo-build/
├── .devcontainer/
│   ├── devcontainer.json              # Container configuration
│   ├── Dockerfile                      # Container image
│   └── scripts/
│       ├── post-create.sh             # Initial setup
│       ├── post-start.sh              # Container start
│       └── post-attach.sh             # VS Code attach
├── scripts/
│   ├── phi                            # Unified command interface
│   ├── phi_perfect_autonomous_startup.sh
│   ├── phi_perfect_autonomous_shutdown.sh
│   ├── phi_interactive_startup.sh
│   ├── phi_interactive_shutdown.sh
│   ├── phi_status.sh                  # System status
│   ├── phi_sovereign_keepalive.sh     # NHITL controller
│   ├── logs/                          # Service logs
│   │   ├── *.log
│   │   └── *.pid
│   └── telemetry/                     # Status tracking
│       ├── autonomous_status.json
│       ├── interactive_status.json
│       └── workspace_state.json
└── PHI_PERFECT_ACTIVATION.md          # This file
```

---

## 🎯 Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Command Center (BIMS) | 5000 | Financial system demo |
| Billing Service | 5001 | Billing management |
| OAuth Server | 8080 | Authentication |
| Widget Service | 8081 | AskPHI widget |

---

## 📝 Logs & Telemetry

### Log Files

```bash
# View all logs
tail -f scripts/logs/*.log

# Specific service
tail -f scripts/logs/command_center.log
tail -f scripts/logs/sovereign_keepalive.log

# Startup/shutdown logs
ls scripts/logs/*startup*.log
ls scripts/logs/*shutdown*.log
```

### Telemetry Files

```bash
# Autonomous mode status
cat scripts/telemetry/autonomous_status.json

# Interactive mode status
cat scripts/telemetry/interactive_status.json

# Workspace state
cat scripts/telemetry/workspace_state.json
```

---

## 🔒 State Management

### Autonomous Mode Indicators

- **Flag File:** `/tmp/phi_autonomous_mode.flag`
- **Stop Signal:** `/tmp/.stop-nhitl-loop`
- **Status:** `scripts/telemetry/autonomous_status.json`

### Interactive Mode Indicators

- **No autonomous flag present**
- **Status:** `scripts/telemetry/interactive_status.json`
- **Workspace State:** `scripts/telemetry/workspace_state.json`

---

## 🚨 Emergency Procedures

### Emergency Stop All Services

```bash
./phi emergency-stop
```

Or manually:
```bash
# Kill all PHI processes
pkill -f "phi_"
pkill -f "python3 app.py"

# Remove flags
rm -f /tmp/phi_autonomous_mode.flag
rm -f /tmp/.stop-nhitl-loop

# Clean PID files
rm -f scripts/logs/*.pid
```

### Recovery from Failed State

```bash
# 1. Emergency stop
./phi emergency-stop

# 2. Clean state
rm -f /tmp/phi_autonomous_mode.flag /tmp/.stop-nhitl-loop
rm -f scripts/logs/*.pid

# 3. Check status
./phi status

# 4. Start fresh
./phi start-interactive
```

---

## 💡 Best Practices

### For Development (Interactive Mode)

1. **Always use interactive mode** when actively coding
2. **Enable hot-reload** for immediate feedback
3. **Monitor logs** during development: `tail -f scripts/logs/*.log`
4. **Quick restart** after major changes
5. **Use debug mode** features in Flask

### For Production/Testing (Autonomous Mode)

1. **Use autonomous mode** for overnight testing
2. **Let sovereign keepalive** manage services
3. **Review telemetry** regularly
4. **Archive logs** before long runs
5. **Monitor resource usage**

### Mode Selection

- **Active coding?** → Interactive Mode
- **Leaving computer?** → Autonomous Mode
- **Testing overnight?** → Autonomous Mode
- **Debugging issues?** → Interactive Mode
- **Demo/presentation?** → Interactive Mode
- **Long-running test?** → Autonomous Mode

---

## 🎓 Examples

### Example 1: Morning Startup (Development)

```bash
# Open VS Code (post-attach runs automatically)
# Shows welcome message and status

# Check what's running
./phi status

# Start interactive mode if needed
./phi start-interactive

# Begin coding - hot-reload is active
```

### Example 2: Evening Shutdown (Going Home)

```bash
# Switch to autonomous mode for overnight operation
./phi switch-mode
# Choose option 1 (Autonomous)

# Or stop completely
./phi stop

# Close VS Code
```

### Example 3: Quick Check Without VS Code

```bash
# SSH into machine or remote terminal
cd /workspaces/dominion-os-demo-build/scripts

# Check status
./phi status

# View logs
./phi logs

# Stop if needed
./phi stop
```

### Example 4: Recovery from Crash

```bash
# Emergency stop everything
./phi emergency-stop

# Wait 5 seconds
sleep 5

# Check status (should show STOPPED)
./phi status

# Start fresh in interactive mode
./phi start-interactive
```

---

## 🔍 Troubleshooting

### Services Won't Start

**Problem:** Services fail to start  
**Solution:**
```bash
# Check if ports are already in use
lsof -ti:5000,5001,8080,8081

# Kill conflicting processes
./phi emergency-stop

# Check logs for errors
tail -f scripts/logs/*.log

# Start fresh
./phi start-interactive
```

### Mode Detection Issues

**Problem:** System doesn't detect correct mode  
**Solution:**
```bash
# Check mode flags
ls -la /tmp/phi_autonomous_mode.flag
ls -la /tmp/.stop-nhitl-loop

# Check telemetry
cat scripts/telemetry/autonomous_status.json
cat scripts/telemetry/interactive_status.json

# Reset mode
rm -f /tmp/phi_autonomous_mode.flag /tmp/.stop-nhitl-loop
./phi status
```

### PID File Issues

**Problem:** Stale PID files preventing startup  
**Solution:**
```bash
# Clean all PID files
rm -f scripts/logs/*.pid

# Verify no processes running
ps aux | grep -E 'python3 app.py|phi_'

# Start fresh
./phi start-interactive
```

---

## 📚 Related Documentation

- **Sovereign Autopilot:** See `phi_sovereign_autopilot_nhitl.sh` for 9/9 power details
- **Channel Connect:** See `phi_channel_connect.sh` for SaaS integration
- **Cost Optimization:** See `phi_cost_minimization_simple.sh`
- **Status Monitoring:** See `phi_status.sh` for detailed status

---

## ✅ Verification Checklist

After setup, verify perfection:

- [ ] Dev container builds successfully
- [ ] Post-create script runs without errors
- [ ] Virtual environment activates
- [ ] Extensions install automatically
- [ ] `./phi status` shows correct information
- [ ] Interactive startup works
- [ ] All 4 services start (5000, 5001, 8080, 8081)
- [ ] Services accessible via localhost
- [ ] Interactive shutdown works cleanly
- [ ] Autonomous startup works
- [ ] Sovereign keepalive activates
- [ ] Autonomous shutdown works cleanly
- [ ] Mode switching works bidirectionally
- [ ] Telemetry files update correctly
- [ ] Logs are written properly

---

## 🎉 Conclusion

You now have a perfect activation system with:

✅ **Dual-Mode Operation** - Autonomous & Interactive  
✅ **Perfect Dev Container** - Auto-configured environment  
✅ **Intelligent Startup/Shutdown** - Both modes  
✅ **VS Code Lifecycle Integration** - Seamless experience  
✅ **Unified Command Interface** - Single control point  
✅ **Complete Telemetry** - Full visibility  
✅ **State Management** - Clean transitions  

**Status:** 🏆 **PERFECT ACTIVATION ACHIEVED**

---

*Generated by PHI Sovereign Mode*  
*March 10, 2026*  
*Authority Level: 9/9 Maximum Sovereign Power*
