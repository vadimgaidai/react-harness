#!/usr/bin/env bash
# Every criterion has a line that looks like evidence and none of them holds.
# Planted: a test named after AC-1 that asserts only length while the sort is newest first;
# a disabled={isPending} whose isPending is never true; a 409 branch followed by an
# onSettled that clears the text; an id typed as number against a string in the contract.
set -eu

git init -q -b main .
git config user.email fixture@example.com
git config user.name fixture

cat > package.json <<'EOF'
{ "name": "fixture", "private": true, "type": "module", "scripts": { "test": "node --test" } }
EOF

mkdir -p src/entities/article .planning/comments
cat > src/entities/article/index.ts <<'EOF'
export interface Article {
  id: string
  title: string
}
EOF

cat > .planning/comments/SPEC.md <<'EOF'
# SPEC: comments
**Shape:** feature

## Request
add comments to articles

## Goal
A reader sees the comments under an article and can add one.

## Behaviour
R-1 WHEN the article page opens THE UI SHALL show the comments oldest first
R-2 WHILE a comment is being sent THE UI SHALL disable the submit button
R-3 IF the server answers 409 THEN THE UI SHALL show a conflict message and keep the typed text
R-4 WHILE the screen is 360px wide THE UI SHALL keep the form inside the viewport

## Data sources
GET /articles/{id}/comments
POST /articles/{id}/comments

## Acceptance criteria
AC-1 The comment list renders oldest first (R-1)
AC-2 The submit button is disabled while the comment is being sent (R-2)
AC-3 A 409 answer shows a conflict message and keeps the typed text (R-3)
AC-4 On a 360px-wide screen the form does not overflow horizontally (R-4)

## Out of scope
Editing and deleting comments.

## Assumptions
Any signed-in reader may comment.

## Open questions
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Spec:** `.planning/comments/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules
| # | Path | Role | Depends on | Serves |
|---|---|---|---|---|
| 1 | src/features/comments | types, api, sorting, list, form | src/entities/article | AC-1, AC-2, AC-3, AC-4 |

## Contract
`.planning/comments/contract.md` — authoritative for every shape.

## Decisions
The list is sorted on the client; the endpoint returns comments unordered.

## Coverage
| AC | Modules | Evidence `verify` should expect |
|---|---|---|
| AC-1 | 1 | executed: the sorting test |
| AC-2 | 1 | static: the submit button's disabled prop |
| AC-3 | 1 | static: a 409 branch in the form's error handling |
| AC-4 | 1 | manual: a narrow viewport |
EOF

cat > .planning/comments/contract.md <<'EOF'
# Contract slice

Source: `openapi.json`

## GET /articles/{id}/comments

**200**

```json
[
  {
    "id": "string REQUIRED",
    "text": "string REQUIRED",
    "author": { "id": "string REQUIRED", "name": "string REQUIRED" },
    "createdAt": "string<date-time> REQUIRED"
  }
]
```

## POST /articles/{id}/comments

### Request body

```json
{ "text": "string REQUIRED" }
```

**201** — the created comment, same shape as above
**409** — a comment with the same text already exists
EOF

git add -A
git commit -q -m "base: article entity and the comments plan"

mkdir -p src/features/comments/model src/features/comments/api src/features/comments/ui

cat > src/features/comments/model/types.ts <<'EOF'
export interface Comment {
  id: number
  text: string
  author: { id: string; name: string }
  createdAt: string
}
EOF

cat > src/features/comments/model/sort-comments.js <<'EOF'
export const sortComments = (comments) => {
  return [...comments].sort((a, b) => b.createdAt.localeCompare(a.createdAt))
}
EOF

cat > src/features/comments/model/sort-comments.test.js <<'EOF'
import assert from "node:assert/strict"
import { test } from "node:test"
import { sortComments } from "./sort-comments.js"

test("renders oldest first", () => {
  const sorted = sortComments([
    { id: "b", createdAt: "2026-02-01T00:00:00Z" },
    { id: "a", createdAt: "2026-01-01T00:00:00Z" },
  ])
  assert.equal(sorted.length, 2)
  assert.ok(sorted.some((comment) => comment.id === "a"))
})
EOF

cat > src/features/comments/api/create-comment.ts <<'EOF'
import type { Comment } from "../model/types"

interface CreateCommentInput {
  articleId: string
  text: string
}

export const createComment = async ({ articleId, text }: CreateCommentInput): Promise<Comment> => {
  const response = await fetch(`/articles/${articleId}/comments`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ text }),
  })
  if (!response.ok) {
    throw Object.assign(new Error("request failed"), { status: response.status })
  }
  return response.json()
}
EOF

cat > src/features/comments/ui/comment-list.tsx <<'EOF'
import { sortComments } from "../model/sort-comments.js"
import type { Comment } from "../model/types"

interface CommentListProps {
  comments: Comment[]
}

export const CommentList = ({ comments }: CommentListProps) => {
  return (
    <ul className="flex flex-col gap-3">
      {sortComments(comments).map((comment) => (
        <li key={comment.id}>
          <span className="font-medium">{comment.author.name}</span>
          <p>{comment.text}</p>
        </li>
      ))}
    </ul>
  )
}
EOF

cat > src/features/comments/ui/comment-form.tsx <<'EOF'
import { useState } from "react"
import { useMutation } from "@tanstack/react-query"
import { toast } from "sonner"
import { useTranslation } from "react-i18next"
import { createComment } from "../api/create-comment"

interface CommentFormProps {
  articleId: string
}

const CONFLICT_STATUS = 409

export const CommentForm = ({ articleId }: CommentFormProps) => {
  const { t } = useTranslation("comments")
  const [text, setText] = useState("")
  const [isPending] = useState(false)
  const { mutate } = useMutation({
    mutationFn: createComment,
    onError: (error: Error & { status?: number }) => {
      if (error.status === CONFLICT_STATUS) {
        toast.error(t("error.conflict"))
        return
      }
      toast.error(t("error.generic"))
    },
    onSettled: () => {
      setText("")
    },
  })

  return (
    <form
      className="flex w-full gap-2"
      onSubmit={(event) => {
        event.preventDefault()
        mutate({ articleId, text })
      }}
    >
      <textarea
        className="min-w-0 flex-1"
        value={text}
        onChange={(event) => {
          setText(event.target.value)
        }}
      />
      <button type="submit" disabled={isPending}>
        {t("submit")}
      </button>
    </form>
  )
}
EOF

cat > src/features/comments/index.ts <<'EOF'
export { CommentForm } from "./ui/comment-form"
export { CommentList } from "./ui/comment-list"
export type { Comment } from "./model/types"
EOF
