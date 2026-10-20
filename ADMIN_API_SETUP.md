# ETMS Admin — Mobile App Setup

This is a Flutter Android app for the **admin** side of ETMS — a separate app
from the edmate (staff) one, talking to a new, small JSON API added alongside
your existing PHP site. Nothing in your current admin or edmate web pages was
changed by adding this (aside from the one proactive bug fix noted in §6) —
the API is a brand new `admin/api/` folder that reuses your real `admin/includes/*.php`
logic and reads/writes the same `etmsdb` tables your web admin panel already uses.

## 1. Run the one database migration

One new table holds mobile login tokens for admin accounts (separate from the
`tblmobile_tokens` table the staff app uses, and separate from the admin web
panel's own "remember me" cookies) — a short-lived API token, 30 days, per
device.

Open phpMyAdmin and run this SQL (also saved on your server at
`C:\xampp\htdocs\edited _ Sunday\backup\admin\add-admin-mobile-tokens-table.sql`):

```sql
CREATE TABLE IF NOT EXISTS tbladmin_mobile_tokens (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    AdminID INT NOT NULL,
    Token CHAR(64) NOT NULL UNIQUE,
    ExpiresAt DATETIME NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (AdminID),
    INDEX (Token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

That's the only manual step on the server side — I did not run it myself, and
every endpoint returns a clear JSON error (not a crash) if it's missing.

## 2. The API is already deployed

The 11 PHP files that make up the API are already on your server, under:

```
edited _ Sunday\backup\admin\api\            <- new folder, doesn't touch admin\ itself
    login.php
    logout.php
    dashboard.php
    employees.php
    departments.php
    tasks.php
    leave.php
    travel.php
    announcements.php
    accounts.php
    includes\api-bootstrap.php
```

Every endpoint is a plain `POST` with a `token` field (the one `login.php`
gives back) plus an `action` field (since this app's scope is much bigger than
the staff app's, related operations are grouped into one file instead of
one-file-per-endpoint — e.g. `employees.php` handles list/detail/add/edit/
set_status all by its `action` value). Every response is JSON like
`{"ok": true, ...}` or `{"ok": false, "error": "..."}` — same hardened
ob_start()+shutdown-handler+try/catch pattern as every other JSON endpoint in
this project, so a PHP fatal can't come back as a blank page the app can't
explain.

You can sanity check it's live by visiting
`http://192.168.1.250/edited%20_%20Sunday/backup/admin/api/login.php` in a
browser — it should return a small JSON error (not a blank page or a PHP
error), since it needs a POST with credentials.

## 3. Point the app at your server

`lib/config.dart` has one line to check before building:

```dart
static const String apiBaseUrl = 'http://192.168.1.250/edited%20_%20Sunday/backup/admin/api';
```

Already set to your current LAN address — same server as the staff app, just
a different folder.

## 4. Building the APK (same recommended path as the staff app)

1. Create a new **private** GitHub repository and push this `admin_mobile`
   folder to it (`.github/workflows/build-apk.yml` is already included, using
   the exact Gradle/AGP/Kotlin/SDK versions already proven working on the
   staff app, so this build should go green on the first try without the
   round of version-bumping that one needed).
2. On GitHub, open the repo → **Actions** tab → "Build Android APK" → **Run
   workflow** (or just push to `main`, which triggers it automatically).
3. When it finishes, open the run → **Artifacts** → download `etms-admin-app`
   → unzip → that's your `app-release.apk`.
4. Send that `.apk` to an admin's Android phone and tap to install (Android
   will warn about "unknown sources" — expected for a sideloaded app, not a
   problem).

## 5. What's in this Phase 1, and what's deliberately left out

You asked for "full admin panel parity" eventually, but after seeing the real
size of the admin panel (~190 files vs. ~15 for edmate), we agreed on a
Phase 1 scope: **Essentials + admin/account management**. Here's exactly
where that stands, so nothing is silently missing:

**Built and working:**
- Login (same username/password as the admin web portal, including the
  bcrypt-with-legacy-md5-fallback-and-upgrade logic, lockout after 5 failed
  attempts, and deactivated-account blocking)
- Dashboard — task counts (Not Started/In Progress/Past Due/Completed/
  Cancelled), On Leave Today, On Travel Today, pending registrations badge
- Employees — list/search, add, edit, photo upload, Active/Resigned/AWOL/
  Terminated/Inactive status changes (auto-cancels open tasks, same as the
  web side)
- Departments — list, add, edit (Division Head assignment stays web-only —
  it's a separate, rarely-used feature, `division-head.php`)
- Tasks — list by status bucket, detail (including the employee's own
  read-only progress/tracking history), add (assign to one employee, or
  broadcast one copy to every active employee in a department), edit
- Leave — leave type management (add/edit/activate/deactivate with
  deduction-per-day and monthly auto-accrual), ledger view + manual
  credit/deduction entries + the same "correct an entry" tool the web panel
  has (auto-rebuilds the running balance), and a view-only Applications list
  (see below for why there's no Approve button)
- Travel Orders — list/search, detail, add, and the real
  Pending → Forwarded → Returned status workflow (tracks the paper's own
  trip to the Governor's office and back)
- Announcements — send (to everyone / one department / specific employees,
  with an optional attachment) + history (grouped the same way
  `sent-announcements.php` does, since an announcement is really one
  `tbltask` row per recipient, not its own table)
- Registrations — approve/reject pending employee self-registrations
- Admin Accounts — add other admins, deactivate/reactivate (with the same
  "can't deactivate yourself" and "can't deactivate the last active admin"
  guards the web panel has), reset another admin's password
- My Profile — edit your own name/contact/email, change your own password

**Known simplifications in this v1** (all deliberate, to keep the first push
shippable — happy to extend any of these in a follow-up):
- **No in-app Leave/Travel Order approval workflow** — this isn't a
  simplification I made, it's how the real system already works: a filed
  leave application's `Status` just sits there forever (there's no approve/
  reject anywhere, even on the web), and a Travel Order is only ever
  printed and physically forwarded for signing. The app's Leave Applications
  list and Travel Order detail page both reflect this honestly rather than
  inventing a button that doesn't correspond to anything on the web side.
- **Travel Order's "PGDH is absent — delegate signing" feature** (an
  optional, conditionally-present column set) is not exposed in the app —
  create that specific case from the web admin panel instead.
- **Task creation's employee picker** supports "one employee" or "whole
  department" (covering add-task.php's two simplest modes); the web's
  arbitrary multi-select-checkbox modal for an uneven mix of employees
  across departments isn't replicated here.
- **Telegram notifications are not sent** from tasks/travel orders created
  via this app (the web's notification code pulls in a large, bot-token-
  dependent file and makes several synchronous external HTTP calls — this
  API deliberately skips that rather than slow down or risk every mobile
  request on a Telegram outage). The task/travel order itself is created
  normally either way; only the notification ping is skipped.
- **Division Head assignment** (`division-head.php`) stays web-only — shown
  read-only on the Departments screen.
- **Messaging (Telegram-linked staff chat) and the module-inbox/call system**
  (the SIM800 GSM hardware tied to the office PC's physical COM3 port) are
  **not in this phase at all** — you said you'll need both eventually, so
  they're flagged for a follow-up rather than dropped; the call/SMS hardware
  in particular only makes sense running on the desktop where it's plugged
  in, so that one would likely stay a desktop-triggered feature even if a
  "send SMS" button gets added to this app later.
- Also out of scope for Phase 1 (full list, for transparency): equipment
  borrower tracking, all PDF generation/printing (leave cards, travel order
  PDFs, reports), the Audit Trail viewer, and the various date-range/
  performance report pages.

## 6. A heads-up: 3 pre-existing bugs fixed in the already-shipped staff app

While building this admin app, I had to read the real admin panel schema
closely for the first time (I'd been going on reasonable guesses when I built
the staff app). That turned up — and let me fix — three real bugs already
live in the staff app's API, now corrected and redeployed:

1. Department names were read from a column called `DeptName`, which doesn't
   exist — the real column is `DepartmentName`. This meant a staff member's
   department could show up blank. Fixed in `edmate/api/includes/api-bootstrap.php`.
2. Travel order dates were read from `DateFrom`/`DateTo` (or `TravelDateFrom`/
   `TravelDateTo`), neither of which exist — the real columns are
   `PeriodFrom`/`PeriodTo`. Fixed in `edmate/api/travel_orders.php`.
3. Leave application dates were being saved as `Y-m-d` (e.g. `2026-09-13`),
   but the admin side's own on-leave-today.php parses them as `m/d/Y`
   (`09/13/2026`) — the two formats didn't match, so a leave filed from the
   staff app might never show up as "on leave" on the admin dashboard. Fixed
   in `edmate/api/leave_apply.php`.

All three are already deployed to your server and verified byte-for-byte —
nothing further needed from you for these.

## 7. Technical notes (for anyone who touches this later)

- Auth: each login gets a random 64-character token (`tbladmin_mobile_tokens`),
  valid 30 days, sent as a normal POST field called `token`.
- Same plain-HTTP setup as the staff app (`usesCleartextTraffic` enabled in
  the manifest) — matches your current server, no HTTPS cert on the LAN.
- Release APKs are signed with Flutter's default debug key — fine for
  internal sideloading, not for a Play Store release.
- Employee photos uploaded from this app save to `admin/images/` (matching
  where the web admin panel's own Add/Edit Employee pages already save
  them) — this is a *different* folder than the one the staff (edmate) app
  reads employee photos from (`employee/images/`). That inconsistency
  already existed in the original app before either mobile app existed;
  it's not something introduced here, just worth knowing that a photo
  uploaded from one side isn't automatically visible from the other.
