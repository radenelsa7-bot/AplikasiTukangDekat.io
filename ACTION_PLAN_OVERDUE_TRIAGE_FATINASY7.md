# 📋 ACTION PLAN - Overdue Items Triage & Recovery
**Date:** 6 Juni 2026  
**Owner:** Fatinasy7 (BE3)  
**Priority:** URGENT  
**Status:** Draft - Ready for Implementation

---

## 📊 EXECUTIVE SUMMARY

### Current Situation
- **4 items OVERDUE** (original end date sudah lewat)
- **1 item IN PROGRESS** (juga overdue)
- **2 items UPCOMING** (belum dimulai, jadwal Jun 8-14)
- **Core infrastructure READY** untuk staging deployment

### Recovery Goal
Triage overdue items dalam 48 jam, reassess timeline, dan unblock dependencies untuk sprint berikutnya.

---

## 🔴 OVERDUE ITEMS ANALYSIS & ACTION PLAN

### ITEM #1: Model & Eloquent Relationships #13
**Status:** 🟨 IN PROGRESS (OVERDUE)  
**Timeline:** May 18-24, 2026 ← **OVERDUE 13 hari**  
**Assignee:** Fatinasy7

#### 📋 Task Description
- Implementation of Eloquent relationships between models
- Scope: Unknown from timeline image (need to check GitHub issue)

#### 🔍 Blocker Analysis
- [ ] Check GitHub issue #13 untuk detail requirements
- [ ] Verify task dependencies (blocking other tasks?)
- [ ] Check if technical blockers exist

#### ✅ Action Plan
**TODAY (6 Juni):**
1. Open GitHub issue #13 and read full requirements
2. Assess current progress (% complete?)
3. Identify what's blocking completion
4. Break down remaining work into 2-3 subtasks

**TOMORROW (7 Juni):**
1. Complete remaining work (should be minimal if "in progress")
2. Create PR with fixes/completions
3. Mark as complete in GitHub projects

**Target Completion:** 7 Juni 2026 (EOD)

#### 📌 Dependencies
- Check if #55 (another Model task) depends on this
- Check if any other tasks are waiting for this completion

---

### ITEM #2: Model & Eloquent Relationships #55
**Status:** 🔴 TODO (OVERDUE)  
**Timeline:** May 18-24, 2026 ← **OVERDUE 13 hari**  
**Assignee:** Fatinasy7

#### 📋 Task Description
- Another Model & Eloquent task (different scope from #13)

#### 🔍 Blocker Analysis
**CRITICAL QUESTION:** Are #13 and #55 the same task or different?
- If same → consolidate and complete
- If different → may have different requirements

#### ✅ Action Plan
**DECISION POINT (6 Juni - EOD):**
1. Open GitHub issue #55 and #13
2. Determine if they're duplicates or different tasks
3. If duplicates → consolidate into single task
4. If different → prioritize by business impact

**NEXT SPRINT (7-8 Juni):**
1. If consolidated with #13, both marked done by 7 Juni
2. If separate, schedule for 8-10 Juni
3. Create PR and mark complete

#### 📌 Dependencies
- Potentially blocks auto-DP payment creation (#61)
- May impact notification integration (#28)

**Recommendation:** Check GitHub issues urgently to consolidate if possible.

---

### ITEM #3: Auto-create DP Payment saat Order dibuat (BR-01) #61
**Status:** 🔴 TODO (OVERDUE)  
**Timeline:** May 25-31, 2026 ← **OVERDUE 6 hari**  
**Assignee:** Fatinasy7  
**Feature Requirements:** BR-01 (Business Rule)

#### 📋 Task Description
- Auto-create Down Payment (DP) when order created
- Scope: Payment automation logic in order creation flow

#### 🔍 Blocker Analysis
- [ ] Depends on Model relationships (#13, #55) - check if complete
- [ ] Check if payment integration (#20 - Reviews & Rating) is blocking
- [ ] Verify database migration exists for DP payment tracking
- [ ] Check if Xendit/Midtrans integration ready (should be from core)

#### ✅ Action Plan
**PHASE 1 - Unblock (6 Juni - EOD):**
1. Verify #13 & #55 completion status
2. Check payment integration status (already done per DEPLOY_STATUS)
3. Review database schema for DP tracking
4. Open GitHub issue #61 for detailed requirements

**PHASE 2 - Implementation (7-9 Juni):**
1. Create migration if needed (DP payment table/fields)
2. Add DP creation logic in Order model/service
3. Write unit tests (DP validation, amount calculation)
4. Write integration test (order creation → DP creation flow)
5. Create PR and link to #61

**Expected Complexity:** MEDIUM (2-3 days if unblocked)  
**Target Completion:** 9 Juni 2026

#### 📌 Dependencies
- ✅ Payment integration (already done)
- ⏳ Model relationships (#13, #55) - must complete first
- Impact: Blocks #28 (notifications for DP payment)

---

### ITEM #4: API Reviews & Rating (FR-23, FR-24) #20
**Status:** ✅ DONE  
**Timeline:** May 25-31, 2026 ← **OVERDUE 6 hari**  
**Assignee:** Fatinasy7  
**Feature Requirements:** FR-23, FR-24

#### 📋 Task Description
- Create/Update/Delete reviews for completed orders
- Get reviews/ratings for services and providers
- Aggregate rating calculation

#### 📝 Update
- Backend branch ready: `feature/backend-120-reviews-rating-api`
- Implemented review creation endpoint and provider rating summary
- Added review factories and service/provider test support
- Fixed review migration and rating distribution logic
- Local runtime verification blocked because PHP CLI is not available in this editor environment

#### 🔍 Blocker Analysis
- [x] Check if Review model exists in codebase
- [x] Verify Order completion status workflow (must have "completed" status)
- [x] Check if database migration for reviews table exists
- [x] Validate rating aggregation logic (average, count)

#### ✅ Action Plan
**PHASE 1 - Assessment (6 Juni - EOD):**
1. Check if Review model/migration exists
2. Review FR-23, FR-24 requirements from GitHub
3. Identify what's already implemented vs. TODO
4. Check database schema completeness

**PHASE 2 - Implementation (7-10 Juni):**
1. Create/update Review model with relationships
2. Implement REST endpoints (POST /reviews, GET /reviews, DELETE)
3. Add rating aggregation (avg, count, distribution)
4. Write comprehensive tests (CRUD, validation, aggregation)
5. Create PR

**Expected Complexity:** MEDIUM-HIGH (3-4 days)  
**Target Completion:** 10 Juni 2026

#### 📌 Dependencies
- ✅ Order Management (already done)
- ✅ User Authentication (already done)
- Impact: Used by Treasurer reports (#36) and notifications (#28)

---

### ITEM #5: Integrasi n8n - Event Notifikasi (FR-21, FR-22) #28
**Status:** 🔴 TODO (OVERDUE)  
**Timeline:** Jun 1-7, 2026 ← **OVERDUE 1 hari**  
**Assignee:** Fajar1180, Fatinasy7  
**Feature Requirements:** FR-21, FR-22  
**CRITICAL:** Team collaboration task (2 assignees)

#### 📋 Task Description
- Event-driven notification system via n8n
- WhatsApp & Email notifications
- Trigger events (order created, payment received, review posted, etc.)

#### 🔍 Blocker Analysis
**TEAM BLOCKER:**
- [ ] Coordination with Fajar1180 required
- [ ] n8n environment setup status (staging ready?)
- [ ] n8n webhook endpoint configuration
- [ ] Event dispatcher implementation status

**TECHNICAL BLOCKERS:**
- ⏳ Depends on #61 (DP payment auto-create for payment events)
- ⏳ Depends on #20 (reviews for review notifications)
- [ ] Check if Event model/system exists

#### ✅ Action Plan
**PHASE 1 - Coordination (6 Juni - URGENT):**
1. **SYNC with Fajar1180 TODAY:**
   - What's his progress on n8n setup?
   - What's blocking him?
   - Can work be split or run in parallel?

2. **Split Task by Component:**
   - Fatinasy7: Backend event dispatcher + webhook integration
   - Fajar1180: n8n workflow setup + testing

**PHASE 2 - Backend Implementation (7-11 Juni):**
1. Create Event dispatcher/queue system
2. Implement webhook sender to n8n
3. Configure retry logic and error handling
4. Write integration tests with mock n8n

**PHASE 3 - Integration & Testing (12-14 Juni):**
1. Connect to staging n8n environment
2. Test complete flows (order → WhatsApp/Email)
3. Create PR and link to #28

**Expected Complexity:** HIGH (4-5 days, team dependent)  
**Target Completion:** 14 Juni 2026  
**BLOCKER:** Team sync required immediately

#### 📌 Dependencies
- ⏳ #61 (DP payment creation - for payment events)
- ⏳ #20 (Reviews - for review events)
- Impact: Unblocks user experience improvements

---

## 🟠 UPCOMING ITEMS - Preparation

### ITEM #6: Finalisasi & Hardening API (FR-37) #37
**Status:** 🔵 TODO (UPCOMING)  
**Timeline:** Jun 8-14, 2026 (FUTURE)  
**Assignee:** Fatinasy7

#### 📋 Scope
- API security hardening
- Request validation improvements
- Error handling standardization
- Rate limiting implementation

#### ✅ Preparation Plan
**WEEKS 1-2 (6-8 Juni - Prep):**
1. Review OWASP API Top 10
2. Audit current error responses (standardization needed?)
3. List all endpoints for validation review
4. Plan rate limiting strategy (Redis-based?)

**WEEK 3 (8-14 Juni - Implementation):**
1. Add/update input validation rules
2. Standardize error response format
3. Implement rate limiting middleware
4. Add security headers (CORS, CSP, etc.)
5. Write security tests

**Dependencies:** None blocking  
**Can start during overdue triage phase** ✅

---

### ITEM #7: Admin Endpoints & Treasurer Report #36
**Status:** 🔵 TODO (UPCOMING)  
**Timeline:** Jun 8-14, 2026 (FUTURE)  
**Assignee:** Fatinasy7

#### 📋 Scope
- Admin dashboard endpoints (FR-25, FR-26)
- Treasurer financial reports
- Payout tracking and reconciliation

#### ✅ Preparation Plan
**WEEKS 1-2 (6-8 Juni - Prep):**
1. Review treasury requirements (FR-25, FR-26)
2. Check if Report model exists
3. Plan endpoint structure (GET /reports/treasury, etc.)
4. Design report data schema

**WEEK 3 (8-14 Juni - Implementation):**
1. Create Admin routes with authentication
2. Implement report generation endpoints
3. Add financial calculations (payouts, commissions)
4. Write authorization tests
5. Create PR

**Dependencies:** 
- Depends on #20 (reviews for commission calculation)
- Depends on #61 (DP payments for financial reports)

**Can start design phase during overdue triage**

---

## 📅 RECOVERY TIMELINE PROPOSAL

```
┌─ IMMEDIATE (6 Juni) ─────────────────────────┐
│ • Triage #13 & #55 (consolidate if possible) │
│ • Sync with Fajar1180 about #28              │
│ • Assess blockers for #61 & #20              │
│ • START design on #37 & #36 (prep work)      │
└──────────────────────────────────────────────┘
         ↓
┌─ SPRINT 1 (7-10 Juni) ───────────────────────┐
│ Priority 1: Complete #13 (EOD 7 Juni)        │
│ Priority 2: Complete #55 (EOD 8 Juni)        │
│ Priority 3: Complete #61 (EOD 9-10 Juni)     │
│ Parallel: Start prep on #37 & #36            │
│ Blocker: Sync with Fajar1180 on #28          │
└──────────────────────────────────────────────┘
         ↓
┌─ SPRINT 2 (11-14 Juni) ──────────────────────┐
│ Priority 1: #20 Reviews & Rating COMPLETE     │
│ Priority 2: Team sync + start #28 (11 Juni)  │
│ Priority 3: #37 API Hardening (start 8 Juni) │
│ Priority 4: #36 Treasury Reports (8+ Juni)   │
└──────────────────────────────────────────────┘
         ↓
┌─ DEPLOYMENT (15 Juni+) ──────────────────────┐
│ • All items complete & tested                │
│ • Smoke test on staging                      │
│ • Ready for production deployment            │
└──────────────────────────────────────────────┘
```

---

## 🎯 KEY DECISIONS TO MAKE TODAY (6 Juni)

| Decision | Owner | Impact | Action |
|----------|-------|--------|--------|
| #13 vs #55 consolidation | Fatinasy7 | Critical - saves 3 days | Review GitHub issues TODAY |
| Fajar1180 availability for #28 | Both | Critical - blocks notifications | Call/message TODAY |
| Model dependencies check | Fatinasy7 | High - unblocks multiple tasks | 2 hour analysis |
| n8n environment readiness | DevOps/PM | High - #28 execution | Verify TODAY |

---

## 📊 ESTIMATED EFFORT SUMMARY

| Item | Status | Duration | Difficulty | Owner | Target Date |
|------|--------|----------|------------|-------|-------------|
| #13 | IN PROGRESS | 1 day | MEDIUM | Fatinasy7 | 7 Juni |
| #55 | TODO | 1 day | MEDIUM | Fatinasy7 | 8 Juni |
| #61 | TODO | 2-3 days | MEDIUM | Fatinasy7 | 9-10 Juni |
| #20 | DONE | 3-4 days | MEDIUM-HIGH | Fatinasy7 | 7 Juni |
| #28 | TODO | 4-5 days | HIGH | Both | 14 Juni |
| #37 | UPCOMING | 3-4 days | MEDIUM | Fatinasy7 | 13-14 Juni |
| #36 | UPCOMING | 3-4 days | MEDIUM | Fatinasy7 | 13-14 Juni |

**Total Effort:** ~18-25 days for 1 developer + team collab for #28  
**Current Capacity:** 9 days remaining in sprint (7-15 Juni)  
**Recommendation:** Parallelize #37 & #36 prep work to optimize timeline

---

## ⚠️ RISK MITIGATION

### Risk 1: #13 & #55 Duplication
- **Impact:** Could waste 2-3 days
- **Mitigation:** Check GitHub issues immediately (6 Juni morning)
- **Fallback:** Consolidate into single PR

### Risk 2: Fajar1180 Unavailable for #28
- **Impact:** Blocks n8n integration for 5+ days
- **Mitigation:** Sync with him today; if unavailable, plan alternative
- **Fallback:** Fatinasy7 handles both backend + n8n config

### Risk 3: Model Relationships Complexity
- **Impact:** Could overflow #13 timeline
- **Mitigation:** Break into smaller PRs; get code review early
- **Fallback:** Extend #13 deadline to 8 Juni

### Risk 4: Dependencies Chain
- **Impact:** #61 & #20 & #28 are interdependent
- **Mitigation:** Parallelize where possible; use mocks/stubs in tests
- **Fallback:** Adjust timeline if blockers emerge

---

## ✅ NEXT ACTIONS (Immediate - Today)

- [ ] **9:00 AM:** Open GitHub issues #13, #55 - check for duplication
- [ ] **10:00 AM:** Slack/message Fajar1180 - check #28 status & availability
- [ ] **11:00 AM:** Analyze #61 blockers (payment integration, DB migration)
- [ ] **12:00 PM:** Analyze #20 blockers (Review model, rating logic)
- [ ] **2:00 PM:** Update this action plan with findings
- [ ] **3:00 PM:** Create prioritized PR list for sprint
- [ ] **EOD:** Commit to daily standup on #13 & #55 progress

---

**Document Version:** 1.0  
**Last Updated:** 6 Juni 2026  
**Next Review:** 7 Juni 2026 (after Sprint 1 kickoff)
