# BranchQ — Branch Appointments & Live Queue Tokens

BranchQ is a mobile banking capstone application built with Flutter, Riverpod, and GoRouter. It enables bank customers to locate branches, check service requirements, reserve appointment slots, and track walk-in queue positions in real time.

---

## 1. Problem Statement

Branch visits are still required for safe deposit lockers, demand drafts, KYC updates, and loan servicing. Customers frequently face long, unpredictable wait times without knowing branch congestion or whether the branch is even open. 

**Goal:** Provide an easy way to locate branches, check live crowd indicators, book 15-minute appointment slots, and track digital queue tokens with live position updates.

---

## 2. Architecture

BranchQ follows the 4-layer client architecture specified in the capstone standard:

```text
lib/
├── app/               # Router (GoRouter), App entry configuration
├── core/              # Shared cross-cutting concerns (BankError, AsyncValueView)
└── features/branch/
    ├── domain/        # Domain entities (Branch, Service, Slot, LiveToken)
    ├── data/          # BranchRepository, simulated API calls & 409 conflict rules[cite: 1]
    ├── state/         # Riverpod providers, StreamProvider for queue polling[cite: 1]
    └── presentation/   # Screens (Finder, Detail, Slot Booking, Live Token)[cite: 1]
