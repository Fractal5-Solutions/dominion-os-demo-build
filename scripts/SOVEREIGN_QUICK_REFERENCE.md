# 🎯 PHI SOVEREIGN POWER MODE - QUICK REFERENCE

## 🚀 INSTANT COMMANDS

### Check Status
```bash
cd /workspaces/dominion-os-demo-build/scripts
bash phi_sovereign_controller.sh status
```

### Change Operating Mode
```bash
# Stay local only (zero cost, default)
bash phi_sovereign_controller.sh mode SOVEREIGN_LOCAL

# Enable smart sync (auto-deploy when cost-effective)
bash phi_sovereign_controller.sh mode INTELLIGENT_HYBRID

# Full cloud priority (for production)
bash phi_sovereign_controller.sh mode CLOUD_PRIORITY
```

### Manual Cloud Sync
```bash
# Check cost first
bash phi_sovereign_controller.sh cost

# Sync if approved
bash phi_sovereign_controller.sh sync
```

### View Cost Dashboard
```bash
bash phi_sovereign_controller.sh cost
```

---

## 🎛️ OPERATING MODES

### Mode 1: SOVEREIGN_LOCAL (Current)
- **Cost:** $0/month
- **Behavior:** All services local, no cloud sync
- **Best for:** Development, testing, low-budget
- **Commands work offline:** YES

### Mode 2: INTELLIGENT_HYBRID
- **Cost:** $5-15/month
- **Behavior:** Smart sync during off-peak hours
- **Best for:** Staging, periodic deployments
- **Auto-sync triggers:**
  - Code commits detected
  - Off-peak hours (3 AM)
  - Cost < $2 per sync
  - Max 4 syncs/day

### Mode 3: CLOUD_PRIORITY
- **Cost:** $50-100/month
- **Behavior:** Real-time cloud sync
- **Best for:** Production traffic, demos
- **Auto-scale:** Enabled

---

## 💰 COST OPTIMIZATION

### Current Budget
- **Monthly Limit:** $10.00
- **Warning at:** $7.50 (75%)
- **Auto-pause at:** $10.00 (100%)

### Cost Per Operation
- Service deployment: ~$0.12
- Cloud Run (idle): $0.00 (min-instances=0)
- Cloud Run (active): ~$0.05/hour
- Git sync: $0.00
- Monitoring: $0.00 (GCP free tier)

### Savings Strategies
1. **Use local services** - Zero cost development
2. **Batch deployments** - Deploy multiple changes at once
3. **Off-peak sync** - Schedule for 3 AM (lower costs)
4. **Auto-pause** - Services scale to 0 when idle
5. **Smart caching** - Avoid redundant deployments

---

## 🔄 SYNC TRIGGERS

### Automatic Sync (INTELLIGENT_HYBRID mode)
- ✅ Git commits detected
- ✅ Off-peak hours (11 PM - 6 AM)
- ✅ Cost estimate < $2.00
- ✅ Budget remaining > $3.00
- ✅ Max 4 syncs per day

### Manual Sync
- ✅ Anytime with approval
- ✅ Shows cost estimate first
- ✅ Requires budget check

### Blocked Sync
- ❌ Peak hours (9 AM - 5 PM) unless urgent
- ❌ Budget exceeded
- ❌ No pending changes
- ❌ Daily sync limit reached

---

## 🛡️ FAILOVER & PROTECTION

### Auto-Failover Scenarios

**Cost Spike Detected**
```
IF cost > $10/month THEN
  1. Pause all cloud services
  2. Switch to SOVEREIGN_LOCAL
  3. Alert admin
  4. Wait for approval to resume
```

**Cloud Service Down**
```
IF gcloud API fails THEN
  1. Mark cloud UNHEALTHY
  2. Serve from local
  3. Queue updates
  4. Retry every 15 min
  5. Auto-resume when healthy
```

**Network Offline**
```
IF no internet THEN
  1. Full sovereign mode
  2. All services local
  3. Queue changes for later sync
  4. NO interruptions
```

---

## 📊 MONITORING

### Real-Time Metrics
```bash
# Current status
bash phi_sovereign_controller.sh status

# Cost tracking
bash phi_sovereign_controller.sh cost

# Service health
bash phi_status.sh

# Logs
tail -f logs/sovereign_controller.log
tail -f logs/cloud_sync.log
```

### Key Metrics Tracked
- Current operating mode
- Monthly cost ($X / $10)
- Pending changes count
- Syncs today (X / 4)
- Last sync timestamp
- Cloud health status
- Local services running

---

## 🔧 TROUBLESHOOTING

### Controller Not Running
```bash
# Check if running
ps aux | grep phi_sovereign_controller

# Restart
pkill -f phi_sovereign_controller
nohup bash phi_sovereign_controller.sh monitor > logs/sovereign_controller.log 2>&1 &
```

### Sync Failing
```bash
# Check GCP auth
gcloud auth list

# Check logs
tail -f logs/cloud_sync.log

# Test connection
gcloud projects list --limit=1
```

### Budget Alert
```bash
# Check current spend
bash phi_sovereign_controller.sh cost

# Force local mode
bash phi_sovereign_controller.sh mode SOVEREIGN_LOCAL

# Pause cloud services
bash phi_cloud_sync_engine.sh pause phi-oauth-server
bash phi_cloud_sync_engine.sh pause phi-askphi-widget
```

### Reset State
```bash
# Clear all state
bash phi_sovereign_controller.sh reset

# Check new status
bash phi_sovereign_controller.sh status
```

---

## 🎯 BEST PRACTICES

### Development Workflow
1. ✅ Code locally first 
2. ✅ Test with local services (port 5000, 5001, 8080, 8081)
3. ✅ Commit to git
4. ✅ Let sovereign controller handle sync
5. ✅ Monitor cost dashboard
6. ✅ Deploy to cloud only when needed

### Cost-Conscious Development
- **DO:** Use SOVEREIGN_LOCAL for dev
- **DO:** Batch multiple changes
- **DO:** Sync during off-peak hours
- **DO:** Monitor budget continuously
- **DON'T:** Deploy every small change
- **DON'T:** Keep unused cloud services running
- **DON'T:** Sync during peak hours

### Production Deployment
1. Test thoroughly in SOVEREIGN_LOCAL
2. Switch to INTELLIGENT_HYBRID for staging
3. Monitor one full day
4. Check cost impact
5. Switch to CLOUD_PRIORITY for launch
6. Set up auto-scaling limits
7. Monitor and optimize

---

## 📞 EMERGENCY COMMANDS

### Immediate Cost Stop
```bash
# EMERGENCY: Stop all cloud spending
bash phi_sovereign_controller.sh mode SOVEREIGN_LOCAL
bash phi_cloud_sync_engine.sh pause phi-oauth-server dominion-os-1-0-main
bash phi_cloud_sync_engine.sh pause phi-askphi-widget dominion-os-1-0-main
```

### Force Local Failover
```bash
# Switch everything local
bash phi_sovereign_controller.sh mode SOVEREIGN_LOCAL
bash phi_quick_start.sh
bash phi_status.sh
```

### Resume After Emergency
```bash
# Check costs first
bash phi_sovereign_controller.sh cost

# Resume if safe
bash phi_sovereign_controller.sh mode INTELLIGENT_HYBRID
bash phi_cloud_sync_engine.sh resume phi-oauth-server dominion-os-1-0-main
bash phi_cloud_sync_engine.sh resume phi-askphi-widget dominion-os-1-0-main
```

---

## 📈 SUCCESS METRICS

### Target KPIs
- ✅ Cost: <$10/month average
- ✅ Uptime: >99.9%
- ✅ Sync time: <5 minutes
- ✅ Autonomy: >95% automated
- ✅ Failover: <30 seconds

### Current Status
```bash
# Get full report
bash phi_sovereign_controller.sh status
bash phi_status.sh
```

---

## 🎓 LEARNING PATH

### Week 1: Foundation
- [x] Start in SOVEREIGN_LOCAL mode
- [x] Run all services locally
- [x] Learn the commands
- [x] Monitor with phi_status.sh

### Week 2: Hybrid Mode
- [ ] Switch to INTELLIGENT_HYBRID
- [ ] Make test commits
- [ ] Watch auto-sync behavior
- [ ] Monitor costs daily

### Week 3: Optimization
- [ ] Analyze sync patterns
- [ ] Optimize batch schedules
- [ ] Fine-tune cost limits
- [ ] Test failover scenarios

### Week 4: Production
- [ ] Deploy to CLOUD_PRIORITY
- [ ] Monitor production metrics
- [ ] Set up alerting
- [ ] Document learnings

---

## 🌟 SOVEREIGNTY PRINCIPLES

1. **Local First** - Everything works offline
2. **Cost Aware** - Know the cost of every action
3. **Auto-Optimize** - AI decides when to sync
4. **Zero Downtime** - Seamless transitions
5. **Self-Healing** - Auto-recovery from failures
6. **Full Control** - Manual override always available

---

**🎉 YOU ARE NOW IN SOVEREIGN POWER MODE**

*Complete autonomy. Zero-cost intelligence. Total control.*

For detailed documentation: [PHI_SOVEREIGN_POWER_MODE_PLAN.md](./PHI_SOVEREIGN_POWER_MODE_PLAN.md)
