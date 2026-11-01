---
name: relish-open-play
description: Find, book and calendar Drew's pickleball open play at Relish Food Hall // Pickleball (Louisville, CO) on CourtReserve. Pulls the bookable Open Play Advanced sessions ("yellow", Drew's default; other levels on request), finds back-to-back 2-hour blocks, checks them against Drew's Google Calendar (telling hard commitments from mere reminders and from Shayna's events), recommends 2–3 blocks, and on request registers him, leaves him on the pay screen, and adds the event to his calendar in his usual style. Use whenever Drew mentions Relish, pickleball open play, ladder play, CourtReserve, "when can I play this week", "book me the Monday 12–2", "put Tuesday in my cart", or wants pickleball time fitted around his calendar, even if he doesn't name Relish.
version: 1.1.0
user-invocable: true
argument-hint: "[which week / level / block to book — or blank for this week's Advanced options]"
---

<!-- Never write a dollar sign directly before a digit in this file: the skill loader treats it as an argument placeholder and replaces it (a ten-dollar price once rendered as "Tue.00"). Write prices as "10 dollars". -->

Find Drew 2-hour pickleball blocks at Relish that fit his week, and book the one he picks. The job has three parts — **find**, **fit**, **book + calendar** — and he usually asks for them in separate messages: first "what are my options", then "book me X" or "put X in my cart". Don't register anything until he names a block.

## Browser

Use **Claude in Chrome** (the `mcp__claude-in-chrome__*` tools), not the built-in browser: Drew's real Chrome is already signed in to CourtReserve and Google Calendar, and the built-in pane isn't. Read the `chrome-browser` skill first, then load every tool in one ToolSearch:

`select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__tabs_close_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__find,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__browser_batch`

Work in your own new tabs (`tabs_context_mcp` with `createIfEmpty: true`). Batch navigate + wait + read steps with `browser_batch`.

## 1. Find sessions on CourtReserve

- Relish's org id is **13679**. Event list: `https://app.courtreserve.com/Online/Events/List/13679`
- CourtReserve moved to a new layout in late Oct 2026. The page loads slowly: wait ~4s after navigating. If `get_page_text` says "No text content found", wait a few more seconds and screenshot or retry.
- Click the **Search** box at the top of the left **Filter** column, type `Open Play Advanced`, press Return, wait ~3s, then read the list. That search also catches the "Ladder Open Play Advanced" hours. Each card reads: a colored level tag (`Open Play Advanced 3.75-4.0`), the title, `Tue, Nov 3rd, 10a - 11a`, the price (10 dollars), spots (`3 of 12 spots remaining` or `FULL`), then a button (`Register`, `Join Waitlist`, `Edit Registration` if he's already in, or `Details`). The little dot beside the spot count is always blue; it doesn't mean the level.
- **Bookable window is about 7 days**; sign-ups open around 8am a week ahead. Cards showing "Registration opens in …" with a `Details` button aren't open yet. So "this week" means today through the last day that still shows `Register`; say which dates you covered.
- **Levels.** Drew names them by color, and the tag on each card shows the color and rating:
  - **yellow** = Advanced 3.75–4.0. Since Nov 2026 most of these hours are titled **"Open Play Advanced"**; the 4–5pm hours are still "Ladder Open Play Advanced". Both count as yellow. This is Drew's default.
  - **blue** = Upper Intermediate 3.5–3.75
  - **green** = Lower Intermediate 3.25–3.5
  - "Ladder Open Play Expert" (4.0+) and "All Levels Ladder Open Play" are different events; leave them out.
  - For blue or green, search the level name (e.g. `Upper Intermediate`) and check the tags.
- Sessions are 1 hour. A **back-to-back block** is two consecutive hours of the same level where *both* hours have open spots. A FULL hour breaks the block.
- **Nearly empty sessions sometimes get cancelled.** If Drew asks which are "kind of empty", the spot count tells you: 11 of 12 remaining means one person is signed up.
- The schedule changes month to month, so always read the live list rather than assuming last month's times.

## 2. Fit against Google Calendar

- Week view: `https://calendar.google.com/calendar/r/week/YYYY/MM/DD`. Weeks start Monday, so a Sun–Sat window spans two weeks; read both. `get_page_text` gives one line per event: `HH:MM to HH:MM, title, <calendar>, <RSVP>, <location>, Color, date`.
- **Two calendars show up.** Lines tagged `drew larsen` are his. Lines tagged `Calendar: Shayna Larsen` are his wife's, so ignore any event that appears *only* on her calendar (her PT, "Shayna Relish", "Relish with Mel", "Moms happy hour", her appointments). Shared events appear on both calendars; count those.
- **Drew puts lots of reminders in his calendar, not just hard commitments.** Judge each one:
  - *Ignore:* entries with only a start time and no end (`11:00, protein shake`, `08:00, reta`), short to-dos (`put trash out`, `checking balance…`, `relish bills …`, `signup relish next week`), and all-day banners (payment due dates, birthdays, "CU/CSU free admissions").
  - *Hard (rule the block out):* 🏐 volleyball at Dawson School or away games (his kid's), appointments (`Drew @ dolbeare…`, haircut, PT on *his* calendar), pickleball or workouts he already has (`pickle w/ dave & krista`, `drew @ crossfit …`, an existing `drew @ relish …`), and family commitments (`sanna @ CU visit`).
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

1. **Check the cart first:** `https://app.courtreserve.com/Online/Payments/Index/13679`. "You don't have any booked items to pay." means nothing is held. If he says he forgot to pay, this is what you'll see: the hold ran out and the spots went back to the pool, so register again from step 2. If the hours are still in the cart, just reopen checkout.
2. On the event list, search `Open Play Advanced` again. Use `find` with the card text ("Register button for Open Play Advanced Tue, Nov 3rd, 10a - 11a"), then `scroll_to` and screenshot to confirm the date, time and yellow tag before clicking.
3. **Register** (list) → event details page (date, time, spots) → **Register** → sign-up page with an Order Summary → **Finalize Registration**. The sign-up page says "You have 15 minutes to finalize payment": finalizing holds the spot for **15 minutes** and lands on the **Checkout** page.
4. Repeat for the second hour. Checkout then lists both hours under **Cart items**. While anything is held, a black **Pay** button also shows in the top bar.
5. **Payment is Drew's step.** Auto mode blocks Claude from clicking Pay (it counts as a real-world transaction), and Drew is fine doing it himself. Leave the Checkout tab open and tell him exactly what to click:
   - Pay with his **punch pass**, never the credit card: the card adds a 2.9% convenience fee, and the pass is prepaid. Each hour uses one punch. The pass is monthly ("Platinum Member Punch Pass (November) (20 punches remaining)"); if the punch count is low, say so.
   - **One hour in the cart:** "Pay By Package" is already selected with the punch pass, so he just clicks **Pay**.
   - **Two hours in the cart:** the payment method defaults to **"Card ending in 1007"** and the black button at the bottom reads Pay plus the card total (about 20.58 dollars). He should instead click **Pay With Package** on each row under Cart items, not that black button.
   - He has **15 minutes**. If he misses it, the cart empties and you redo step 3 (the calendar event can stay).
6. Check it worked: on the list, each registered hour shows **Edit Registration** instead of Register, and its spot count dropped by one.
7. If the session is less than 24 hours away, mention Relish's rule: a no-show or a cancellation inside 24 hours is still charged.

## 5. Add it to Google Calendar (every booking; he expects it)

First check his calendar for that day: if a `drew @ relish …` event already covers the block (e.g. you're re-adding hours after a missed payment), don't make a second one.

Drew's style for Relish, pickleball and workouts:

- **One event covering the whole block** (10:00–12:00), not one per hour, on the `drew larsen` calendar.
- **Title**, lowercase: `drew @ relish yellow` for Advanced (`drew @ relish blue` for Upper Intermediate). If he's playing with named people, use `drew @ relish w/ Will`. Older entries used "yellow ladder @ relish" and "drew @ relish adv ladder"; the current form is `drew @ relish <color>`.
- **Color Peacock**, no location, no guests, default notification.

Steps:

1. Open `https://calendar.google.com/calendar/r/eventedit?text=drew+%40+relish+yellow&dates=20261103T100000/20261103T120000`. Use local times with no `Z`; his calendar runs on Mountain time. Check the title, date and times on the form.
2. Click the color circle next to "drew larsen", `find` "Peacock, set event label", and click it. The default is orange, which is wrong.
3. Click **Save** (top). There are no guests, so no invite goes out.
4. Check it: open `https://calendar.google.com/calendar/r/day/YYYY/MM/DD` and `find` the event. It should list 10:00–12:00 with Color: Peacock.

## Wrap up

Close the tabs you opened, but leave the CourtReserve Checkout tab open for him. Then tell him: what's held in his cart, that payment is still his to do within 15 minutes (with the punch-pass instructions above), and that the calendar event is in.
