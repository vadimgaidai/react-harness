# Mutations & Cache Invalidation

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.
> This file is the **shape**: where the mutation lives, what it is named, which layer it may import from. The **policy** — how narrowly to invalidate, when `setQueryData` replaces an invalidation, when an optimistic update is warranted — is the `tanstack-query` skill (`react-harness` plugin). Load it too when you are writing the data layer.

Mutations live in the **feature** that owns the action, and invalidate the **entity** keys that the action affects.

```typescript
// src/features/[feature]/api/[feature].mutations.ts
import { useMutation, useQueryClient } from "@tanstack/react-query"

import { [feature]Api } from "./[feature].api"

import { [entity]Keys } from "@/entities/[entity]"

export const use[Feature]Mutation = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: [feature]Api.submit,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [entity]Keys.all() })
    },
    onError: (error) => {
      console.error("[feature] failed:", error)
    },
  })
}
```

Rules visible in this example:

- Mutation hooks are colocated with the api in `api/[name].mutations.ts`.
- The mutation imports query keys from the entity it touches (`@/entities/[entity]`) — features may depend on entities, never the reverse.
- Side-effects (cache invalidation, storage) belong in `onSuccess` / `onError`, not in the component.

