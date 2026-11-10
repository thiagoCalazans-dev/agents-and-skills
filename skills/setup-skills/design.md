# Design

How the skills handle this repo's user interface.

## Design system

- **Source:** `<path to design.md or the design system>`
- Screens use only the design system's tokens and components. Colour, spacing and typography come from the tokens, never from hard-coded values.
- Interface copy follows the tone set in the design system.

<!-- Fill in what exploration found: component library (e.g. shadcn/ui), tokens file, brand guide. -->

## Prototypes

The Designer uses `prototype`'s UI branch to deliver the **expected result** of a ticket with a new screen or a layout change.

- **Where:** on branch `prototype/<issue number>`, out of the main branch (`commands.md`). It keeps only the validated decision.
- **Screenshots:** saved on the branch itself, in `prototype-captures/`, and linked on the ticket. Sizes: `<desktop | mobile | desktop and mobile>`.
- **Approval:** a human approves the screen before the ticket becomes `ready-for-agent`.
- **Later changes:** go back to the same branch, edit, and take new screenshots.

The command that runs the prototype and takes the screenshots is in `commands.md`.
