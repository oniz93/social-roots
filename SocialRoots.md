# Business Requirement Document (BRD)
**Project Name:** Social Roots (Working Title)
**Platform:** iOS & Android (Flutter)
**Date:** Jan 26, 2026
**Version:** 1.0

---

## 1. Executive Summary
**Social Roots** is a personal customer relationship management (CRM) application that gamifies social interactions. It utilizes a "digital garden" metaphor where every contact in a user’s phone is represented by a specific plant. Interactions (calls, texts, meetups) act as "water." Lack of interaction results in visual decay (wilting) of the plant. The goal is to combat social isolation and relationship decay through positive reinforcement, visual incentives, and cognitive offloading (notes/reminders).

---

## 2. Technical Stack Recommendation
*   **Frontend Framework:** Flutter (Dart)
    *   *Reasoning:* Single codebase for iOS/Android, high-performance rendering engine.
*   **Animation Engine:** Rive
    *   *Reasoning:* Essential for the "Wilt/Growth" state machines. Allows fluid blending between "Healthy" and "Sick" states without massive frame-by-frame asset files.
*   **Local Database:** Isar
    *   *Reasoning:* Local-first architecture for privacy and offline speed.
*   **Backend/Auth:** Supabase or Firebase
    *   *Reasoning:* Cloud backup, AI processing functions, authentication.
*   **AI Integration:** Google Gemini or OpenAI API
    *   *Reasoning:* Contextual icebreaker generation and sentiment analysis of notes.

---

## 3. Core Functional Requirements

### 3.1. Onboarding & "Greenhouse" Setup
**FR-001: Permission Handling**
*   The app must request access to Contacts.
*   *Interaction:* If denied, the app offers a "Manual Mode" where users type names manually (high friction, but necessary fallback).
*   *Privacy:* The app must explicitly state that contact data is processed locally and not sold.

**FR-002: The Seed Selection (First Import)**
*   User is presented with a list of contacts sorted by frequency (if OS allows) or A-Z.
*   User selects "Core Circle" contacts to import immediately.
*   **Feature - "The Quiz":** For the first 3 contacts, the app asks: "How often do you want to talk to this person?"
    *   *Option A:* Every few days -> Assigns **High Maintenance Plant** (e.g., Orchid, Fern).
    *   *Option B:* Weekly -> Assigns **Medium Plant** (e.g., Monstera, Sunflower).
    *   *Option C:* Monthly/Rarely -> Assigns **Low Maintenance Plant** (e.g., Cactus, Snake Plant).

### 3.2. The Garden (Home Dashboard)
**FR-003: Garden Visualization**
*   **Grid View:** A clean grid showing pots. Thirsty plants float to the top automatically.
*   **Immersive View:** A horizontal scrollable shelf (parallax effect).
*   **Visual Indicators:**
    *   *Soil Dryness:* Soil color changes from dark brown (wet) to light tan (dry).
    *   *Droop Factor:* Rive animation input shifts based on `% of time elapsed` since last contact.

**FR-004: Weather System (Global Health)**
*   If >80% of plants are healthy, the background shows a sunny day.
*   If <50% are healthy, the background becomes overcast or rainy.
*   *Idea:* This creates a subtle psychological desire to fix the "vibe" of the app.

### 3.3. The Plant Mechanic (The Core Loop)
**FR-005: Watering Logic**
*   **The Action:** User taps a plant -> Selects "Log Interaction."
*   **Watering Types (Input):**
    *   *Drop (Quick Text/Meme):* Restores 20% hydration.
    *   *Cup (Phone Call):* Restores 50% hydration.
    *   *Watering Can (Hangout/Meal):* Restores 100% hydration + adds "Bloom" effect (sparkles).
*   **Interaction:** User can hold-to-water (filling a circular progress bar) for haptic satisfaction.

**FR-006: Decay & Sickness (The "Wilt" Engine)**
*   **Stages of Decay (Rive States):**
    1.  **Thriving:** Upright, swaying, vibrant colors.
    2.  **Thirsty:** Slight droop, "feed me" icon appears.
    3.  **Wilting:** Leaves curl, colors desaturate (turn yellowish).
    4.  **Critical:** Petals fall off, stem bends 90 degrees.
    5.  **Dormant (Not Dead):** The plant turns into a dry stick. It never "dies" (to avoid user guilt), but it requires a "Revival" event (e.g., a long phone call) to grow back.

### 3.4. Relationship Management (CRM)
**FR-007: Note Taking**
*   Each plant has a "Journal" tab.
*   **Quick Tags:** Users can tap pre-set tags: "Birthday," "Gift Idea," "Work," "Family."
*   **Rich Text:** Supports bullet points (e.g., for listing kids' names).

**FR-008: The "Remember This" Feature**
*   User inputs a fact: "She is going for surgery on Friday."
*   App allows setting a **One-Time Reminder** linked to that note.
*   *Notification:* "Ask [Name] how the surgery went today."

### 3.5. AI Assistant & Icebreakers
**FR-009: Contextual Icebreakers**
*   **Input:** The app reads the last 3 notes for that contact.
*   **Prompt:** "Generate 3 casual text openers for [Name] based on these notes: [Notes]."
*   **Output UI:** Three chat bubbles appear. Tapping one copies it to the clipboard and opens WhatsApp/iMessage directly.

**FR-010: "The Nudge"**
*   If a plant is in "Critical" state, the AI suggests a "Low Friction" interaction.
*   *Example:* "Send a funny GIF about [Interest from notes]. It’s been 3 weeks."

---

## 4. Detailed Interaction Design & UX

### 4.1. Haptics & Audio
*   **Watering:** Haptic feedback should simulate water flow (light, rapid taps).
*   **Revival:** When a dormant plant is watered, play a specific "success" chord and heavy haptic thud.
*   **Soundscapes:** Optional ambient nature sounds when the garden is open.

### 4.2. Gestures
*   **Swipe Right on Plant:** Quick Log (Add "Just Thinking of You" text interaction).
*   **Swipe Left on Plant:** Snooze (Delay decay for 24 hours—e.g., if the user is on vacation).
*   **Pinch to Zoom:** Inspect the plant details (leaves texture).

### 4.3. Deep Linking
*   The "Water" button should offer direct links:
    *   "Call" -> Opens System Phone Dialer.
    *   "Message" -> Opens WhatsApp / iMessage / Telegram (user configurable per contact).
    *   "Email" -> Opens Mail client.

---

## 5. Gamification & Progression

### 5.1. The "Green Thumb" Level
*   User earns XP for every interaction logged.
*   **Levels unlock cosmetics:**
    *   Level 5: Ceramic Pots (replace default plastic ones).
    *   Level 10: Exotic Seeds (Unlock Bonsai, Venus Flytrap).
    *   Level 20: Garden Themes (Zen Garden, Cyberpunk Greenhouse, Cottagecore).

### 5.2. Collectibles (The "Sticker Book")
*   Interacting with a contact on their Birthday unlocks a special "Birthday Badge" for that plant.
*   Maintaining a "Streak" (never letting the plant wilt for 6 months) unlocks a "Golden Aura" for that plant.

### 5.3. "Seasons"
*   Implement seasonal events.
    *   *Winter:* Plants get snow on them.
    *   *Autumn:* Falling leaves background.
*   *Goal:* Keeps the UI fresh and encourages users to check in.

---

## 6. Notifications Strategy
*Avoid "Notification Fatigue" at all costs.*

**FR-011: Smart Scheduling**
*   Do not send notifications for all plants at once.
*   **The "Morning Dew" Summary:** One notification at 9:00 AM listing the 3 most thirsty plants.
    *   *Copy:* "Mike, Sarah, and Dad are looking thirsty today. 💧"
*   **The "Wilt Warning":** Only triggers if a plant is about to hit "Critical" state.
    *   *Copy:* "Emergency! Your Orchid (Jessica) is losing petals!"

---

## 7. Monetization Strategy (Freemium)

### 7.1. Free Tier
*   Unlimited Contacts.
*   Basic Plant Types (Fern, Cactus, Flower).
*   Standard Watering.
*   Ads: None (Ads ruin the aesthetic).

### 7.2. Premium Tier ("Botanist Pass") - Subscription or One-Time
*   **Features:**
    *   **AI Icebreakers:** Unlimited generation (Free tier gets 3/day).
    *   **Cosmetics:** Premium Pots, Backgrounds, Plant Skins.
    *   **Cloud Sync:** Backup garden to cloud (Multi-device support).
    *   **Data Insights:** "Relationship Health Check" graphs. "Who do you neglect the most?"
    *   **Widget:** Interactive Home Screen widget (Water directly from home screen).

---

## 8. Technical Architecture & Data Model

### 8.1. Data Model (Dart/Isar Schema)

```dart
@collection
class Plant {
  Id id = Isar.autoIncrement;

  @Index()
  late String contactId; // Links to OS Contact
  
  late String displayName;
  late String plantType; // 'cactus', 'rose', 'bonsai'
  late int difficultyLevel; // 1 (Easy) to 3 (Hard)

  late DateTime lastWatered;
  late DateTime plantedDate;
  
  // 0.0 to 100.0 - Calculated dynamically based on (Now - lastWatered) / difficulty
  double get currentHealth => calculateHealth(); 
  
  // List of history logs
  final interactions = IsarLinks<Interaction>();
  
  // Notes and Metadata
  final notes = IsarLinks<Note>();
}

@collection
class Interaction {
  Id id = Isar.autoIncrement;
  late DateTime timestamp;
  late String type; // 'call', 'text', 'meetup'
  late String? summary; // Optional user text
}
```

### 8.2. Logic: The Decay Algorithm
*   **Formula:**
    `Health = 100 - ( (HoursSinceWatering - GracePeriod) / DecayRate )`
*   **Variables:**
    *   *Grace Period:* Time before health starts dropping (e.g., Cactus = 7 days, Rose = 2 days).
    *   *Decay Rate:* How fast it drops once it starts (e.g., Rose drops 10% per hour, Cactus drops 1% per hour).

---

## 9. Edge Cases & Risks

### 9.1. The "Breakup" Scenario
*   *Risk:* User falls out with a friend. Seeing their plant wilt causes anxiety/sadness.
*   *Solution:* **"Compost" Feature.**
    *   User can Archive/Compost a plant.
    *   Animation: The plant is gently removed, and the pot is put in storage.
    *   It no longer sends notifications but history is kept.

### 9.2. Duplicate Contacts
*   *Risk:* User has "Mom" and "Mom Cell".
*   *Solution:* Merge detection. If user selects a contact that shares a phone number with an existing plant, prompt to merge.

### 9.3. Vacation Mode
*   *Risk:* User goes offline for 2 weeks. All plants die. User quits app in frustration.
*   *Solution:* **"Garden Sitter" Mode.**
    *   User activates "Vacation Mode." All decay pauses for X days.
    *   *Visual:* A "Scarecrow" or "Sprinkler" appears in the garden managing things while user is gone.

---

## 10. Future Roadmap (Post-MVP)

*   **Group Gardens:** Create a shared garden with a spouse to track shared relationships (e.g., "Mutual Friends"). Both can water the plants.
*   **Import History:** Scan Call Logs/SMS logs (Android only) to *automatically* water plants if the user forgets to log it manually.
*   **AR Mode:** Place the plant pot on your real desk using Augmented Reality to check its health.

---

This document outlines a product that is not just a tool, but an emotional companion. By using **Flutter and Rive**, the "sickness" of the plants will feel organic and visceral, driving the user behavior effectively.