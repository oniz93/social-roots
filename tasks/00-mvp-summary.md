# MVP Task Summary

## Social Roots - MVP Development Tasks

This document provides an overview of all tasks required to build the MVP.

---

## Task Dependency Graph

```
Task 01: Project Setup
    └── Task 02: Data Models
    └── Task 03: Contact Permission
    └── Task 12: Navigation & Routing
            └── Task 04: Plant Health Engine
                    └── Task 05: Garden Home Screen
                    └── Task 06: Plant Detail Screen
                            └── Task 07: Watering Interaction
                            └── Task 08: Notes & Journal
                    └── Task 09: Onboarding Flow
                    └── Task 10: Notifications
                    └── Task 11: Settings & Preferences
            └── Task 13: Rive Animations (parallel)
```

---

## Task List by Priority

### HIGH Priority (Core MVP)
| Task | Name | Est. Time | Dependencies |
|------|------|-----------|--------------|
| 01 | Project Setup | 2-3h | None |
| 02 | Data Models | 3-4h | 01 |
| 03 | Contact Permission | 3-4h | 01, 02 |
| 04 | Plant Health Engine | 4-5h | 01, 02 |
| 05 | Garden Home Screen | 6-8h | 01, 02, 04 |
| 06 | Plant Detail Screen | 5-6h | 01, 02, 04, 05 |
| 09 | Onboarding Flow | 5-6h | 01, 02, 03, 04 |
| 12 | Navigation & Routing | 2-3h | 01, All screens |

### MEDIUM Priority (Enhanced MVP)
| Task | Name | Est. Time | Dependencies |
|------|------|-----------|--------------|
| 07 | Watering Interaction | 4-5h | 01, 02, 04, 06 |
| 08 | Notes & Journal | 4-5h | 01, 02, 06 |
| 10 | Notifications | 4-5h | 01, 02, 04, 08 |
| 11 | Settings & Preferences | 3-4h | 01, 04, 10 |
| 13 | Rive Animations | 8-10h | 01, 04 |

---

## Estimated Total Time

| Priority | Tasks | Hours |
|----------|-------|-------|
| HIGH | 8 | 31-39h |
| MEDIUM | 5 | 23-29h |
| **Total** | **13** | **54-68h** |

---

## Suggested Sprint Plan

### Sprint 1: Foundation (Week 1)
- [x] Task 01: Project Setup
- [ ] Task 02: Data Models
- [ ] Task 03: Contact Permission
- [ ] Task 04: Plant Health Engine

**Deliverable:** Database, models, and core health logic

### Sprint 2: Core Screens (Week 2)
- [ ] Task 05: Garden Home Screen
- [ ] Task 06: Plant Detail Screen
- [ ] Task 12: Navigation & Routing

**Deliverable:** Navigable app with garden and detail views

### Sprint 3: Onboarding & Polish (Week 3)
- [ ] Task 09: Onboarding Flow
- [ ] Task 07: Watering Interaction
- [ ] Task 08: Notes & Journal

**Deliverable:** Complete user journey from install to daily use

### Sprint 4: Engagement (Week 4)
- [ ] Task 10: Notifications
- [ ] Task 11: Settings & Preferences
- [ ] Task 13: Rive Animations (can overlap with other work)

**Deliverable:** Full MVP ready for TestFlight

---

## Key Files Created

Each task file contains:
- Objective & Context
- Detailed Implementation (with code)
- Acceptance Criteria
- Dependencies & Blockers

### Task Files
1. `tasks/01-project-setup.md`
2. `tasks/02-data-models.md`
3. `tasks/03-contact-permission.md`
4. `tasks/04-plant-health-engine.md`
5. `tasks/05-garden-home-screen.md`
6. `tasks/06-plant-detail-screen.md`
7. `tasks/07-watering-interaction.md`
8. `tasks/08-notes-journal.md`
9. `tasks/09-onboarding-flow.md`
10. `tasks/10-notifications.md`
11. `tasks/11-settings-preferences.md`
12. `tasks/12-navigation-routing.md`
13. `tasks/13-rive-animations.md`

---

## MVP Feature Scope

### Included in MVP
- Contact import with permission handling
- Manual contact entry fallback
- Plant assignment based on contact frequency quiz
- Garden grid view with health indicators
- Weather system based on garden health
- Plant detail with health status
- Watering with 3 interaction types
- Notes with tags and reminders
- Morning Dew daily notifications
- Wilt Warning alerts
- Vacation mode
- Snooze individual plants
- Compost (archive) plants
- Data export

### Deferred to Post-MVP
- AI Icebreakers
- Premium subscription
- Cloud sync
- Group gardens
- Auto-import from call/SMS logs
- AR mode
- Seasonal events
- XP and leveling system
- Collectible badges
- Custom plant skins

---

## iOS-Specific Considerations

- Minimum iOS 13.0
- Request contacts permission with clear privacy message
- Local notifications require permission
- Background App Refresh for timely notifications
- CocoaPods for iOS dependencies
- TestFlight for beta testing

---

## Getting Started

1. Read `tasks/01-project-setup.md`
2. Create the Flutter project
3. Follow the dependency chain
4. Mark tasks complete as you go
5. Test on iOS Simulator frequently
