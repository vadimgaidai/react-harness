# Components — where they live, not how they're built

> The *how* (extending a primitive, styling, icons) is a UI conventions skill
> if one is loaded (e.g. `react-harness`'s `ui-conventions`) — this
> file only decides the folder. Placeholders: `[name]` kebab-case, `[Name]`
> PascalCase.

| What it is | Where it lives |
|---|---|
| A base primitive (shadcn or hand-installed) | `src/components/ui/[name].tsx` — CLI-managed, flat, never edited to serve one caller |
| A domain wrapper around a primitive, used by one module | that module's own `components/` |
| A form component | that module's own `components/`, one form per file (`[name]-form.tsx`); its schema is `<module>/schemas.ts`, never inline |
| A domain-free component used by two+ modules | `src/components/[name].tsx` |
| A compound component (`.Root` + coupled sub-parts) | a folder — `src/components/[name]/` globally, or `<module>/components/[name]/` locally |

- `src/components/ui/` stays flat and CLI-managed; the barrel-import hook
  blocks importing it as a barrel — always the direct sub-path,
  `@/components/ui/button`, never `@/components/ui`.
- A wrapper that renders one feature's copy or reads one feature's types is
  not generic, however many places call it — see
  [references/placement.md](placement.md) for the actual test.
- Compound components are folder-sized by definition: two or more sub-parts
  that only make sense together (`Tabs.Root` + `Tabs.List` + `Tabs.Panel`)
  don't belong in the flat `components/ui/` folder — they get their own
  folder, local or global by the same promotion test as any other component.

```
src/components/[name]/
├── [name].tsx          # the compound root + sub-components, or split further
├── [name]-item.tsx     # a sub-part large enough to earn its own file
└── index.ts            # export { [Name] } from "./[name]"
```

## Never

- Copy a `components/ui/` primitive's source to tweak one style — extend it
  in the module or global component that wraps it.
- Reach into a module's internals from outside — `@/features/[name]/components/[x]`
  is never a valid import; only the barrel is (see
  [references/barrels.md](barrels.md)).
