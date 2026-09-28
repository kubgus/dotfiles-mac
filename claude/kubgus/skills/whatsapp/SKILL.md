---
name: whatsapp
description: Driving WhatsApp Web through a browser to read chats or manage group membership - reading a group's messages, poll votes or member list, adding and removing people from groups, or sending a group invite to someone who cannot be added directly. Use whenever a task touches WhatsApp at all: a group name, "check what they said in the group", "who voted", "add them to the group", "move the parents to the new group", or any request to reconcile a roster against a chat. Read this before the first navigation, because WhatsApp Web's DOM defeats the obvious approaches in ways that look like a broken script rather than a wrong selector.
---

# WhatsApp Web

Read `kubgus:browsing` first for the approach-agnostic discipline and the Playwright MCP
mechanics. Everything below is WhatsApp-specific and was learned the hard way against the
live site on 2026-09-28.

## The read-only rule, and its two exceptions

**Never send a message.** Kubo drives all parent and leader communication himself. That is
the default and it does not bend.

Two things are not "sending a message" and are allowed when he has asked for them:

1. **Group membership.** Adding and removing people. Note that both post a system line into
   the group that every member sees, so they are outward-facing even though no message is
   typed.
2. **Group invites.** When a number refuses to be added (see *Refused adds* below),
   WhatsApp offers to invite them privately instead. Sending that invite is allowed - it is
   the only way to get that person into the group.

Anything else typed into a chat is a message. **Check what you are focused on before
typing**: the composer is a `[role="textbox"]` *inside* `#main`; the chat search box is an
`INPUT` in `#side`. Assert the difference before every `type` call.

## Reading the DOM

**Use `textContent`, never `innerText`.** This is the single biggest trap. WhatsApp
virtualises almost every list, and `innerText` is layout-dependent - it returns `''` for
rows that exist in the DOM but are not laid out. `textContent` returns them fine. A member
list that reads as ten empty strings is this bug, not an empty list.

Expect icon names to be inlined in the text, because the icons are elements with text
content: a row reads `ic-person-add-filledAdd member`, not `Add member`. Match with
`includes` or a trailing-anchored regex rather than equality, or match the whole string
including the icon prefix.

**A synthetic `element.click()` often does nothing.** React listens for real pointer
events. It works for some plain list rows and silently fails for chat rows and the
add-member picker, where it returns "clicked" and changes nothing. Use the MCP's
`browser_click` with a CSS selector. Playwright's `:has-text()` is the reliable way in.

**`browser_evaluate` hangs on some modals.** A broad `querySelectorAll` while the
add-member picker is open has wedged the call for the full idle timeout twice. Keep
evaluates inside a modal tiny and scoped - `document.querySelector('div[role="dialog"]')
?.textContent?.slice(0, 400)` is the workhorse and has never hung.

## Navigating

The chat list virtualises, so `document.querySelector` on a chat title usually misses, and
worse, it sometimes *hits a stale node* that is positioned behind a different row - the
click then lands on whatever is on top. Playwright reports this as "subtree intercepts
pointer events".

**Always navigate by search**: focus `#side input`, `fill` the group name, press Enter.
That opens the first hit. Verify you landed by reading `#main header`'s first line before
doing anything else; opening the wrong group and then editing its membership is the
expensive mistake here.

The group's full member list is the header's second line, but saved contacts appear there
as bare first names. For anything that needs identification, open **Group info** (click
`#main header`), expand the `N more` row, and read the participant rows - those give
`~SavedName+421 xxx xxx xxx` or the raw number.

## Contacts are saved under the child's name, often twice

In this troop, a parent's contact is saved under their *child's* name, and both parents are
often saved that way - so a group shows `Jan Novak` twice and those are two different
adults. Raw counts of poll votes or members therefore overstate families.

**Search by phone number, not by name.** The add-member picker resolves a number to its
saved contact and shows the name, so searching `0900111222` gives you exactly one
`Jan Novak` and searching `0900333444` gives you the other. That is the only clean
way to disambiguate.

## Adding members

Group info -> `Add member` -> search -> click the result row -> repeat -> `Add members`.

- **Non-contacts can be added.** They appear under a `Not in your contacts` heading. Do not
  conclude from a miss that the picker only searches contacts - it does not.
- **A miss means the number has no WhatsApp account**, and shows as
  `No chats, contacts or messages found`. Nothing can be done from the web client; that
  person needs reaching another way. Try the international form (`+421…`) once before
  concluding it, but a real account resolves in local form too.
- **Existing members are labelled `Already added to group`** in the result row. Use this to
  work out which of a family's two numbers is the one already in - search both, add the one
  without the label.
- **Turn the `Message history: Send recent messages to the selected member` toggle ON**
  (Kubo, 2026-09-28). It defaults on; confirm it rather than assume. New parents otherwise
  join blind to the announcement they are being added for.
- Adding to a group inside a **community** raises a second dialog,
  `Add N people to community?`, which also puts them in the community announcement group
  and general member chat. There is no way to add to a community group without it.

## Refused adds, and the invite path

Some accounts do not allow being added to groups. The add then partly fails and you get
`Couldn't add +421 xxx xxx xxx. You can invite them privately to join this group.` The
others in the same batch still go through.

Take the `Invite to group` button, then the send control - it carries `aria-label="Next"`,
not "Send". This is the second allowed exception to the read-only rule.

## Order of operations for a transfer

Moving a family between groups is **add to the new group first, remove from the old one
second**. Reversed, there is a window where the family is in no group at all, and if
anything fails in between they stay there. Half-applied membership surgery across several
groups is worse than not starting: nobody can tell afterwards which half ran.

Close the arithmetic at the end - `input = added + already there + refused + impossible`,
with every refused and impossible number named.

## The community-add confirmation drops the session

Confirming `Add N people to community?` has repeatedly logged the isolated profile straight
out - three attempts, two of which dropped, and **the batch does not commit when it drops**.
The member count is unchanged afterwards, so a batch that looks sent may not be.

Treat it as unreliable rather than as a failure: re-read the group's member count after
every community add, and never assume a confirm landed. If it drops twice on the same
batch, stop writing and hand the list over rather than re-running it a third time, because
each attempt is one more chance of a partial commit nobody can audit.

## Sessions

The Playwright MCP profile is `--isolated`, so the login never persists and **dies with the
server**. It has also dropped mid-task on a network change, landing back on the QR screen
with `#pane-side` gone.

Landing on the QR screen is a full stop: say so and ask Kubo to scan. Never touch a login.
Check `!!document.querySelector('#pane-side')` before a batch of writes, not just at the
start of the session, so a drop is caught before it eats half a transfer.

History on this device is partial (`Syncing paused`, `See more chat history on the app`),
so an absent message is not evidence that it was never sent.

## Poll votes

Open `View votes`, then scroll the panel to force each option's voters to load - they
render lazily. `See all` drills into one option and needs a Back click. Resolve voters
against the group's member list before quoting a number, because of the two-contacts-per-
family problem above.
