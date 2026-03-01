# dominion-2083 Repository Specification

**Repository:** Fractal5-Solutions/dominion-2083
**Type:** Strategy Video Game (2083 Future Timeline)
**Status:** 🟡 Active Development
**Commercial Product:** Part of Dominion OS Core ecosystem
**Canonical Compliance:** 🔴 0% (Critical gap)

---

## Purpose

Strategy video game set in the year 2083, integrating Dominion OS themes with futuristic gameplay. Features deterministic multiplayer, agentic AI, and historically-grounded scenarios using licensed real-world datasets.

---

## Expected Artifacts

### Game Engine
```
engine/
└── unreal/          # Unreal Engine 5 project structure
    ├── Content/     # Game assets, blueprints, levels
    ├── Source/      # C++ gameplay code
    ├── Config/      # Engine configuration
    └── Plugins/     # Custom UE5 plugins
```

### Deterministic Server
```
server/
└── tick_server/
    ├── sim_server.py           # Main deterministic simulation server
    ├── tick_engine.py          # Tick-based simulation (same seed → same output)
    ├── state_manager.py        # Game state serialization
    ├── network_sync.py         # Client synchronization
    └── tests/
        └── determinism_test.py # 100-tick verification
```

**Determinism Requirements:**
- Same seed + same inputs = byte-for-byte identical game state
- No external randomness (all RNG seeded)
- No time-based logic (tick-based only)
- State digests at every 10 ticks for verification

### AI Agents
```
ai/
└── agents/
    ├── population_abm/         # Agent-Based Modeling for populations
    │   ├── population_sim.py   # Demographic simulation
    │   ├── migration_model.py  # Population movement
    │   └── economic_agents.py  # Economic behavior
    ├── faction_planner/        # Strategic AI for factions
    │   ├── strategic_ai.py     # Long-term planning
    │   ├── diplomacy.py        # Inter-faction relations
    │   └── resource_optimizer.py
    └── hero_micro/             # Tactical unit control
        ├── pathfinding.py
        ├── combat_ai.py
        └── squad_tactics.py
```

### Data Pipeline
```
data/
├── sources/
│   └── manifest.md             # Licensed dataset inventory
│       # World Bank, UN, IMF, HYDE (historical land use),
│       # IPUMS (population data), licenses documented
├── ingest/
│   ├── pipeline.py             # ETL pipeline with checksums
│   ├── validate.py             # Data validation
│   └── transform.py            # Game-ready format conversion
└── game_data/
    ├── demographics.db         # Processed population data
    ├── economics.db            # Historical economic data
    └── geography.json          # Map and terrain data
```

**Data Licensing:**
- All datasets documented with license terms
- Attribution in game credits
- No copyrighted material in version control
- Checksums for data integrity

### CI/CD Workflows
```
.github/workflows/
├── ci-build.yml                # Build game + run tests
├── ci-server.yml               # Server integration tests
└── ci-release.yml              # Package for distribution
```

**CI Gates:**
- Unreal Engine build succeeds
- Python server tests pass (including determinism_test.py)
- SBOM generated for all dependencies
- Container scan (fail on CRITICAL)
- Ethics board sign-off required for PR affecting `ai/agents/` or `data/sources/`

### Health Checks
```
health/
└── smoke_test.sh               # Quick server health verification
    # Tests:
    # 1. Server starts successfully
    # 2. 10-tick simulation completes
    # 3. State digest matches expected
```

### Discovery & Integration
```
discovery/
└── report-channels.json        # Game server discovery manifest

autocoder/
└── drivers/
    └── game_product_driver.py  # Autocoder integration for scaffolding
```

---

## Dependencies

**Technical Dependencies:**
- **dominion-os-1.0:** Kernel API for policy enforcement, capsule signing
- **dominion-cloud-computer:** Hosts authoritative game servers, model registry
- **dominion-autocoder:** Scaffolding and automation driver
- **Unreal Engine 5:** Game engine (Epic Games license)
- **Python 3.11+:** Server runtime
- **Licensed Datasets:** World Bank, UN, IMF, HYDE, IPUMS

**Team Dependencies:**
- **Game Director:** Design, narrative, gameplay balance
- **Data Lead:** Dataset licensing, ETL pipeline, attribution
- **Tech Lead:** Server architecture, determinism, multiplayer
- **Ethics Board:** Sensitivity review for historical scenarios (@ethics-board)
- **Security Team:** Infrastructure security (@security-team)

---

## Optimal State

**Game Server:**
✅ Deterministic tick server operational
✅ 100-tick test produces identical state digests across runs
✅ Multiplayer synchronization tested
✅ Signed capsules generated for authoritative matches

**AI Agents:**
✅ Population ABM integrated with demographic data
✅ Faction AI makes strategic decisions using economic models
✅ Hero micro AI handles tactical combat

**Data Pipeline:**
✅ All datasets licensed and documented
✅ Checksums validated on every ingest
✅ No PII, no copyrighted material in version control

**Game Engine:**
✅ Unreal Engine 5 project structure complete
✅ Custom plugins for Dominion OS integration
✅ Builds succeed in CI

**CI/CD:**
✅ Automated builds for server + game client
✅ Health checks passing in staging
✅ Ethics review workflow enforced

---

## Acceptance Criteria

### Server Determinism
- [ ] `sim_server.py` implements tick-based simulation
- [ ] Same seed + inputs → byte-for-byte identical state
- [ ] `tests/determinism_test.py` runs 100-tick simulation 3 times with identical digests
- [ ] State serialization deterministic (no dict/set randomness)
- [ ] No time.time() or datetime.now() calls in simulation logic

### Data Integration
- [ ] `data/sources/manifest.md` lists all datasets with license terms
- [ ] Attribution in game credits and documentation
- [ ] ETL pipeline checksums validate on every run
- [ ] No PII or copyrighted material committed
- [ ] Data pipeline runs successfully in CI

### AI Agents
- [ ] Population ABM simulates 10,000+ agents
- [ ] Faction AI makes strategic decisions (diplomacy, resource allocation)
- [ ] Hero micro AI controls units in combat scenarios
- [ ] All AI reproducible (seeded RNG)

### Game Engine
- [ ] Unreal Engine 5 project builds without errors
- [ ] Custom plugins integrated
- [ ] Game launches and loads 1 test level

### CI/CD
- [ ] `ci-build.yml` builds game + server successfully
- [ ] `ci-server.yml` runs determinism_test.py and passes
- [ ] Health check `health/smoke_test.sh` passes
- [ ] SBOM generated for Python dependencies
- [ ] Container scan passes (no CRITICAL vulnerabilities)

### Ethics & Governance
- [ ] Ethics board sign-off for historical scenarios (@ethics-board)
- [ ] PR policy enforces GAME:ALPHA label for sensitive changes
- [ ] Security team review for server infrastructure (@security-team)

### Capsule & Reproducibility
- [ ] Authoritative matches generate signed capsules
- [ ] `release/deploy-report.json` generated with deployment status
- [ ] Capsule includes state digest, seed, version, timestamp
- [ ] Verification: replaying match from capsule produces identical state

---

## Current State

**Assessment (as of Feb 28, 2026):**

✅ **Description:** Professional commercial description on GitHub
✅ **Topics:** Searchable tags (strategy-game, unreal-engine, 2083, agentic-ai)
✅ **Protection:** Branch protection enabled
❌ **File Structure:** 0% canonical structure implemented
❌ **CI Workflows:** Not present or not canonical
❌ **Deterministic Server:** Not implemented
❌ **Data Pipeline:** Not implemented
❌ **AI Agents:** Not implemented
❌ **Signed Capsules:** Not implemented
❌ **Ethics Workflow:** Not configured

---

## Gap Summary

**Status:** 🔴 **CRITICAL - 0% Canonical Compliance**

**Missing Components:**
1. **Deterministic server** - Core gameplay requirement not implemented
2. **Data pipeline** - Licensed datasets not acquired, ETL not built
3. **AI agents** - Agentic gameplay features not developed
4. **Unreal Engine structure** - Game engine project not initialized
5. **CI workflows** - No automated builds, health checks, or safety gates
6. **Ethics workflow** - Sensitive historical scenarios not reviewable
7. **Signed capsules** - Match reproducibility not possible

**Risk Assessment:**
- **High:** Game cannot launch without deterministic server
- **High:** Potential legal risk without dataset licensing documentation
- **Medium:** Gameplay limited without AI agents
- **Medium:** Development velocity slow without CI automation

**Estimated Effort:** 8-12 weeks for 3-person team (Director, Data Lead, Tech Lead)

---

## Immediate Actions

### Week 1-2 (Foundation)
1. **Assign Owners**
   - Appoint Game Director (design ownership)
   - Appoint Data Lead (dataset licensing, ETL)
   - Appoint Tech Lead (server architecture, multiplayer)

2. **Dataset Licensing**
   - Acquire licenses for World Bank, UN, IMF datasets
   - Document HYDE and IPUMS usage compliance
   - Create `data/sources/manifest.md` with attribution

3. **Deterministic Server Skeleton**
   - Implement `server/tick_server/sim_server.py` (basic tick loop)
   - Create `tests/determinism_test.py` (10-tick version)
   - Verify same seed → same output (even if game logic is stub)

4. **Ethics Sign-Off**
   - Present historical scenario approach to ethics board
   - Get approval for data usage and narrative sensitivity
   - Document review in repository

### Week 3-4 (Infrastructure)
5. **CI Workflows**
   - Create `ci-build.yml` (Python server tests)
   - Create `ci-server.yml` (determinism_test.py)
   - Add health check `health/smoke_test.sh`

6. **Unreal Engine Initialization**
   - Create UE5 project structure in `engine/unreal/`
   - Integrate with server (basic networking)
   - Verify builds in CI (may require custom runner)

### Week 5-8 (Gameplay)
7. **Data Pipeline**
   - Implement `data/ingest/pipeline.py` (ETL for 1 dataset)
   - Add checksum validation
   - Load data into `data/game_data/demographics.db`

8. **AI Agents Phase 1**
   - Population ABM basic simulation (1,000 agents)
   - Faction AI strategic planner (stub decisions)
   - Hero micro AI pathfinding

9. **100-Tick Determinism**
   - Extend determinism_test.py to 100 ticks
   - Verify state digests match across 3 runs
   - Generate first signed capsule

### Week 9-12 (Polish)
10. **Authoritative Server Deployment**
    - Deploy server to dominion-cloud-computer
    - Generate signed capsules for test matches
    - Verify capsule replay produces identical states

11. **Security Review**
    - Server infrastructure review by @security-team
    - Penetration testing for multiplayer exploits
    - Approve for alpha testing

---

## Integration Points

**With dominion-os-1.0 (Kernel):**
- Use AI Gateway for model queries (faction AI strategic decisions)
- Use capsule signing service for authoritative matches
- Policy enforcement for in-game moderation

**With dominion-cloud-computer:**
- Host authoritative game servers
- Store signed capsules in model registry
- Multi-tenant server orchestration

**With dominion-autocoder:**
- Use `game_product_driver.py` for scaffolding new features
- Dry-run mode for code generation reviews
- Apply mode creates Draft PRs with GAME:ALPHA label

**With ethics board:**
- Review historical scenarios for sensitivity
- Approve data usage and narrative approach
- Sign off on releases involving controversial topics

---

## Success Metrics

**Technical:**
- ✅ 100-tick determinism test passes with 100% match rate
- ✅ Server handles 100+ concurrent players
- ✅ Signed capsules generated for all authoritative matches
- ✅ Zero state desync in multiplayer after 1-hour sessions

**Gameplay:**
- ✅ 10,000+ population agents simulated
- ✅ Faction AI makes 10+ strategic decisions per game
- ✅ Hero micro AI wins 80%+ of scripted tactical scenarios

**Compliance:**
- ✅ All datasets documented with licenses
- ✅ Ethics board approval for all releases
- ✅ CI passing with health checks + determinism tests
- ✅ Security review approved

**Business:**
- 🎯 Alpha release Q4 2026
- 🎯 Beta release Q2 2027
- 🎯 100+ alpha testers recruited

---

**End of dominion-2083 Specification**
