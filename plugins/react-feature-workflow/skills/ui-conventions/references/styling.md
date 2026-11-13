# Styling, icons and component shape

Answers: may I use this Tailwind class, token or value here; which classes survive a right-to-left language; how does an icon get sized and labelled; when does a component split?

## Tokens and dark mode

- Semantic tokens only: `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`. Never a raw hex, never a palette color (`text-gray-500`) or an arbitrary value where a token exists.
- No `dark:` overrides in components. Dark mode is a token-layer concern, so a `dark:` in a component means the token set is wrong. Fix the tokens (the `theme-sync` agent), not the component.
- A component that only looks right in one theme is not done.

## Utilities

- `size-*` when width equals height: `size-4`, not `h-4 w-4`.
- `truncate`, not `overflow-hidden text-ellipsis whitespace-nowrap`.
- Conditional classes go through `cn()`: `cn("rounded-md", isActive && "bg-accent")`, never a template string with a ternary, which `tailwind-merge` cannot dedupe.
- `gap-*` over `space-y/x-*`, because space utilities break on wrapping and on flex direction changes.
- `className` on an exported component is for layout positioning only (margins, grid placement). Anything else belongs inside the component or in a variant.
- Spacing and sizes come from the Tailwind scale. A raw px value is a signal the design has no matching token; surface that rather than hardcoding it.

## Logical sides for right-to-left languages

Arabic and Hebrew read right to left, and the whole layout mirrors: the gap before an icon moves
to the other side. A physical class (`ml-2`, `pl-4`, `left-0`, `text-left`, `rounded-l-md`,
`border-l`) stays on the left and breaks the mirrored layout. A logical class means "the start
of the line": left in a left-to-right language, right in Arabic, and the browser picks the side
from `dir`.

| Physical | Logical |
|---|---|
| `ml-*` / `mr-*` | `ms-*` / `me-*` |
| `pl-*` / `pr-*` | `ps-*` / `pe-*` |
| `left-*` / `right-*` | `start-*` / `end-*`; `inline-s-*` / `inline-e-*` from Tailwind 4.2, which deprecates `start-*` / `end-*` |
| `text-left` / `text-right` | `text-start` / `text-end` |
| `rounded-l-*` / `rounded-r-*` | `rounded-s-*` / `rounded-e-*` |
| `border-l` / `border-r` | `border-s` / `border-e` |
| `space-x-*` with `space-x-reverse` | `gap-*` |

```tsx
<ChevronRight className="ms-auto size-4" />
```

```tsx
<ChevronRight className="ms-auto size-4 rtl:rotate-180" />
```

A directional icon (an arrow, a chevron, "back", "next") points the other way in a
right-to-left layout and flips with `rtl:rotate-180`; a symmetric icon (search, close, check)
does not. Vertical sides (`mt-*`, `pb-*`, `top-*`) have no direction and stay as they are.
Check `package.json` once for the Tailwind version before using `inline-s-*`.

## A scale class must exist in the project's theme

A Tailwind scale class is a claim about the project's theme, not about default Tailwind. A project that resets a namespace in `@theme` (`--<ns>-*: initial`) keeps only the keys it redefines, and every other class in that namespace silently emits no CSS: no type error, no lint error, just a missing style. A reset radius scale that redefines only `xs`/`sm`/`md` makes `rounded-xl` a no-op. This holds for any tokenized namespace (radius, spacing, font-size, color); the example is not the rule.

`@theme` is Tailwind v4. In a v3 project `theme.extend` in `tailwind.config` only adds to the default scale, while a key set directly under `theme` replaces that part of it; that direct key is v3's reset. Check `package.json` once to know which file to read.

Before the first use of a scale class from a namespace, check that file for it. If the namespace is reset, only the keys listed there exist. If the project runs `eslint-plugin-better-tailwindcss` with `no-unknown-classes`, the check is machine-enforced and is not repeated by hand.

## A design value with no matching token

Use the nearest existing token, or ask the user before adding a token to `@theme`. An arbitrary bracket value (`rounded-[12px]`, `text-[13px]`, `gap-[7px]`, `w-[327px]`) is never the answer for a property that has a token scale; brackets are reserved for values no scale owns (`backdrop-blur-[200px]`).

## Icons

- The library named by `iconLibrary` in `components.json` (`lucide-react` in these projects), so icons the CLI adds with a component match the ones written by hand.
- Inside a `Button`, mark placement with `data-icon="inline-start"` / `data-icon="inline-end"` and let the Button own the sizing: no `size-*` on the icon there.
- A standalone icon gets an explicit `size-*` and, when it carries meaning, an accessible label through `t()`.
- A prop that takes an icon takes the component (`icon={CheckIcon}`), never a string key looked up in a map.

## Component shape

- Extract a sub-component once JSX passes ~80 lines, or when a chunk owns its own state.
- Three or more render branches are early returns, not a ternary chain in JSX (`code-shape` §Ternaries); when a helper is extracted is `code-shape` too.
- One file does one thing: fetch, map, or render. Growing state moves into a `use-*` hook.
- Loading, empty and error are real states, each with its own render. A list that renders nothing on empty is a bug.
