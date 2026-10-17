---
name: relish-open-play
description: Find, book and calendar Drew's pickleball open play at Relish Food Hall // Pickleball (Louisville, CO) on CourtReserve. Pulls the bookable Ladder Open Play sessions (Advanced / "yellow" by default), finds back-to-back 2-hour blocks, checks them against Drew's Google Calendar (telling hard commitments from mere reminders and from Shayna's events), recommends 2–3 blocks, and on request registers him and adds the event to his calendar in his usual style. Use whenever Drew mentions Relish, pickleball open play, ladder play, CourtReserve, "when can I play this week", "book me the Monday 12–2", or wants pickleball time fitted around his calendar, even if he doesn't name Relish.
version: 1.0.0
user-invocable: true
argument-hint: "[which week / level / block to book — or blank for this week's Advanced options]"
---

Find Drew 2-hour pickleball blocks at Relish that fit his week, and book the one he picks. The job has three parts — **find**, **fit**, **book + calendar** — and he usually asks for them in separate messages: first "what are my options", then "book me X". Don't register anything until he names a block.

## Browser

Use **Claude in Chrome** (the `mcp__claude-in-chrome__*` tools), not the built-in browser: Drew's real Chrome is already signed in to CourtReserve and Google Calendar, and the built-in pane isn't. Read the `chrome-browser` skill first, then load every tool in one ToolSearch:

`select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__tabs_close_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__find,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__browser_batch`

Work in your own new tabs (`tabs_context_mcp` with `createIfEmpty: true`). Batch navigate + wait + read steps with `browser_batch`.

## 1. Find sessions on CourtReserve

- Relish's org id is **13679**. Event list: `https://app.courtreserve.com/Online/Events/List/13679`
- Click the search box at the top of the left filter column, type `Ladder`, press Return, wait ~3s, then `get_page_text`. Each event reads as: category, title, `Mon, Oct 19th, 12p - 1p`, `$10.00`, spots (`6 of 12 spots remaining` or `FULL`), then a button (`Register`, `Join Waitlist`, or `Details`).
- **Bookable window is about 7 days.** Events showing "Registration opens in …" with a `Details` button aren't open yet. So "this week" means today through the last day that still shows `Register`; say which dates you covered.
- **Levels** (CourtReserve shows each with a colored dot, and Drew names them by color):
  - **yellow** = Advanced 3.75–4.0 → title **"Ladder Open Play Advanced"**. This is Drew's default.
  - **blue** = Upper Intermediate 3.5–3.75 → "Ladder Open Play Upper Intermediate"
  - **green** = Lower Intermediate 3.25–3.5
  - Don't mix in look-alikes: "Open Play Advanced" (no "Ladder", e.g. Tue/Thu 9–10a) and "Ladder Open Play Expert" (4.0+) are different events.
- Sessions are 1 hour and $10. A **back-to-back block** is two consecutive hours of the same ladder level where *both* hours have open spots. A FULL hour breaks the block.
- As of Oct 2026 the Advanced ladder pairs were roughly: Mon 12–2 and 4–6, Tue 7–9 and 10–12, Wed 12–2 and 4–6, Thu 10–12, Fri 7–9, 12–2 and 4–6, Sat 8–10. Use that only to orient yourself; the schedule changes, so always read the live list.

## 2. Fit against Google Calendar

- Week view: `https://calendar.google.com/calendar/r/week/YYYY/MM/DD`. Weeks start Monday, so a Sun–Sat window spans two weeks; read both. `get_page_text` gives one line per event: `HH:MM to HH:MM, title, <calendar>, <RSVP>, <location>, Color, date`.
- **Two calendars show up.** Lines tagged `drew larsen` are his. Lines tagged `Calendar: Shayna Larsen` are his wife's, so ignore any event that appears *only* on her calendar (her PT, "Shayna Relish", "Relish with Mel", "Moms happy hour"). Shared events appear on both calendars; count those.
- **Drew puts lots of reminders in his calendar, not just hard commitments.** Judge each one:
  - *Ignore:* entries with only a start time and no end (`11:00, protein shake`, `08:00, reta`), short to-dos (`put trash out`, `checking balance…`, `relish bills $130`, `signup relish next week`), and all-day banners (payment due dates, birthdays, "CU/CSU free admissions").
  - *Hard (rule the block out):* 🏐 volleyball at Dawson School or away games (his kid's), appointments (`Drew @ dolbeare…`, haircut, PT on *his* calendar), pickleball or workouts he already has (`pickle w/ dave & krista`, `drew @ crossfit …`), and family commitments (`sanna @ CU visit`).
  - *In between:* `Placeholder - …` and `Needs RSVP` items. Don't rule a block out over one; mention it.
- Relish is in Louisville and Drew is in Boulder. Leave about 15 minutes of travel on each side, and point out tight fits (e.g. "starts right after your 11:45 appointment").

## 3. Report

Answer in plain words, short, no headers (his global CLAUDE.md applies):

- **2–3 recommended blocks**, best first. For each: the day, date and time, what's near it on his calendar, and spots left per hour. Flag any hour with 4 or fewer spots left as "sign up soon".
- One line on early-morning (7–9am) alternatives if there are open ones.
- A short list of what you ruled out and why (volleyball, already playing, an hour is FULL…).
- One line saying what you ignored: Shayna-only events and reminders.
- End by saying nothing is registered yet.

## 4. Book (only when he names a block)

1. Reopen the event list and search `Ladder` again. Use `find` with the exact card text ("Register button for Ladder Open Play Advanced Mon, Oct 19th, 12p - 1p"), then `scroll_to` and screenshot to confirm it's the right card before clicking.
2. Register → event details page → **Register** → "Register to Event" page (shows the total) → **Finalize Registration**. That holds the spot and starts a **15-minute payment window**.
3. Repeat for the second hour. The payment page then lists both hours as rows in one cart.
4. **Payment is Drew's step.** Auto mode blocks Claude from clicking Pay (it counts as a real-world transaction), and Drew is fine doing it himself. Leave the Process Payment tab open and tell him exactly what to click:
   - Pay with his **punch pass package**, never by credit card: the card adds a 2.9% convenience fee, and the package is prepaid. Each hour uses one punch.
   - On a one-row page, "Pay By Package" is already selected, so he just clicks Pay.
   - On a multi-row cart the Payment Method **defaults to his credit card**. He should click the green **Pay With Package** button on each row, not the Pay button at the bottom.
   - Remind him of the 15-minute window.
5. Check it worked: back on the list, each registered hour now shows **Edit Registration** instead of Register, and its spot count dropped by one.
6. If the session is less than 24 hours away, mention Relish's rule: a no-show or a cancellation inside 24 hours is still charged.

## 5. Add it to Google Calendar (every booking; he expects it)

Drew's style for Relish, pickleball and workouts:

- **One event covering the whole block** (12:00–14:00), not one per hour, on the `drew larsen` calendar.
- **Title**, lowercase: `drew @ relish yellow` for Advanced (`drew @ relish blue` for Upper Intermediate). If he's playing with named people, use `drew @ relish w/ Will`. Older entries used "yellow ladder @ relish" and "drew @ relish adv ladder"; the current form is `drew @ relish <color>`.
- **Color Peacock**, no location, no guests, default notification.

Steps:

1. Open `https://calendar.google.com/calendar/r/eventedit?text=drew+%40+relish+yellow&dates=20261019T120000/20261019T140000`. Use local times with no `Z`; his calendar runs on Mountain time. Check the title, date and times on the form.
2. Click the color circle next to "drew larsen", `find` "Peacock, set event label", and click it. The default is orange, which is wrong.
3. Click **Save** (top). There are no guests, so no invite goes out.
4. Check it: open `https://calendar.google.com/calendar/r/day/YYYY/MM/DD` and `find` the event. It should list 12:00–14:00 with Color: Peacock.

## Wrap up

Close the tabs you opened, but leave the CourtReserve payment tab open for him. Then tell him: what's registered, that payment is still his to do (with the package instructions above), and that the calendar event is in.
