# Reviewing: ui-conventions

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- a raw hex, an arbitrary Tailwind value, or a scale class from a namespace the project's `@theme`/`tailwind.config` has reset without that key
- an icon-only button with no accessible name
- a label not associated with its field, or an error not tied to the field it describes (`aria-describedby`, `aria-invalid`)
- a `dark:` override inside a component instead of a token fix
- a compound component part holding its own copy of state `Root` already owns — a part's own local state is not this
- a context-reading part rendered outside its `Root` that fails silently instead of throwing a named error
- state, a Provider or a Context added to a compound component for the pattern's sake, with no behaviour that needs it — a part's own local state nothing else reads is allowed
- controlled and uncontrolled state both driving the same compound component at once
- a wrapper around a primitive that swallows `onKeyDown`, re-implements focus trapping, or breaks roving tabindex instead of forwarding to the primitive
- a button inside a form with no explicit `type`, so an action button submits
- focus or typed input lost on pending or error — the control should be disabled, not unmounted, and the text should stay
- a primitive's source copied and tweaked instead of extended via `ComponentProps`
- custom markup where a shadcn component exists: a hand-made empty state, spinner, skeleton, callout, badge, separator, icon over an input, or toggle loop (`references/components.md`)
- a `Dialog`, `Sheet` or `Drawer` with no title, an item outside its group, a `TabsTrigger` outside `TabsList`, an `Avatar` with no fallback
- `asChild` in a Base UI project or `render` in a Radix one; `sonner` in a Base UI project
- a manual `z-index` on an overlay, a template-string ternary where `cn()` was meant
- a physical horizontal class (`ml`, `mr`, `pl`, `pr`, `left`, `right`, `text-left`, `rounded-l`, `border-l`) where the logical one was meant, or a directional icon with no `rtl:rotate-180`
- an icon from a library other than `iconLibrary` in `components.json`
- `FC<IProps>` instead of the props typed on the parameter
- a user-facing string that is not a `t()` key, including a number, date or plural formatted by hand instead of through the project's i18n formatting
- a component that only looks right in one theme
- loading, empty or error collapsed into the same render, or an empty list rendering nothing
- a new compound part added for symmetry with no caller that needs it
- `h-4 w-4` instead of `size-4` (an icon inside a `Button` takes no size at all), or `space-y/x-*` instead of `gap-*`
