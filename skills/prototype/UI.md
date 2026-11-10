# UI Prototype

Generate versions of a screen **inside the app**, switchable from a floating bar, take screenshots, and bring a human's choice. When there is a ticket, the approved prototype becomes its **expected result**.

If the question is about logic or state rather than looks, this is the wrong branch: use [LOGIC.md](LOGIC.md).

## Before starting

1. Read `docs/agents/design.md` and the design system it points to (tokens, components, tone). Every version uses only its tokens and components.
2. If you got a ticket, read the ticket and its parent spec: the screen must show what the acceptance criteria ask for.
3. If the ticket already has your comments with versions and a reply from the human, go straight to "Answer the human".
4. Create branch `prototype/<ticket number>` from an updated main branch (or return to it if it exists).

## How many versions

- **New screen:** 3 **radically different** versions, at most 5. Different in structure (layout, information hierarchy, primary action), not just colour or copy.
- **Adjustment to an existing screen:** a single version, the proposal.

Write the plan in one line at the top of the prototype file:

> "Three versions of the settings page, switchable via `?variant=`, on the `/settings` route."

## Where to mount it

**A: inside an existing page (preferred).** Versions live on the same route, picked by the `?variant=` param. Data fetching, params and auth stay; only the rendering swaps. This also covers something new that naturally lives inside a page (a new section, a new card, a new step in a flow).

**B: a new page (last resort).** Only when there is no page the thing fits in. Create a throwaway route following the project's convention, with `prototype` in the path, and the same `?variant=`. Check first: is there really no existing page? An empty route hides problems a populated one would show.

## Build the versions

Each version is a clearly named component (`VariantA`, `VariantB`…). A switcher on the route picks by the param:

```tsx
// pseudo-code, adapt to the project's framework
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

The **floating bar** sits fixed at the bottom-centre of the screen:
- a left and a right arrow that cycle through the versions;
- the current version's label, e.g. `B (sidebar)`.

How the bar behaves:
- Switching updates the URL param through the project's router, so the version survives a reload and can be shared.
- The `←` and `→` keys also switch, except when an `<input>`, `<textarea>` or `[contenteditable]` has focus.
- It looks clearly different from the page, so it isn't mistaken for the design being judged.
- It is hidden in production builds (`process.env.NODE_ENV !== 'production'` or equivalent).

Avoid:
- **versions that differ only in colour or copy:** that's a tweak, not a prototype;
- **sharing layout between versions:** a common `<Header>` is fine, a common `<Layout>` isn't;
- **wiring versions to real writes:** use read-only data or a stub.

## Screenshots and asking for approval

1. Run the prototype and take a screenshot of each version, at the sizes in `docs/agents/design.md`. Use the available browser or the evidence command in `commands.md`.
2. Save the screenshots on the branch itself, in a `prototype-captures/` folder next to the prototype. Commit and push the branch, so they're versioned and linkable.
3. Comment on the ticket with:
   - the branch;
   - how to run the prototype;
   - one line per version, with its idea and the screenshot link;
   - the question: which version, or what to change.

End in `waiting for approval #<ticket>`. The wait belongs to the human, not to this run.

## Answer the human

Read the human's latest reply on the ticket:

- **Picked a version, no changes:** keep only that version in the prototype, retake the screenshots, and comment the approved version, its screenshots and the branch link on the ticket. End in `prototype approved #<ticket>`.
- **Asked for changes** (including "B's header with C's sidebar", which is often the real design): apply them, retake the screenshots, comment, and end in `waiting for approval #<ticket>` again.
- **Dropped the screen:** comment the reason and end in `prototype rejected #<ticket>: <reason>`.

## What not to do

- **Carry the prototype into the main branch.** It was written without tests or error handling; the implementation rewrites it properly from the screenshots and the branch.
- **Delete the branch after approval.** It's the source of the ticket's expected result.
