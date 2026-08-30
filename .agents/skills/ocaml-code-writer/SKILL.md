---
name: ocaml-code-writer
description: |
  OCaml specialization of code-writer. Named list combinators over folds and
  recursive walks; never List.fold_right a filter or map. Use when writing or
  reviewing OCaml, Melange, .ml/.mli, List.fold_right, fold_left, concat_map,
  or list pipelines.
---

# OCaml code writer

Activate with `code-writer`.

A fold or recursive walk that **builds a list** is a combinator you did not
name. Name it. Do this at generation time, not in review.

## Pick by the result

| Result | Combinator |
|---|---|
| list, one output per input | `List.map` |
| list, keep some | `List.filter` |
| list, keep-and-change | `List.filter_map` |
| list, nested lists flattened | `List.concat_map` |
| two lists by a predicate | `List.partition` |
| bool | `List.exists` / `List.for_all` |
| one element | `List.find_opt` |
| a scalar, map, or other non-list | `List.fold_left` |

Same names on `Seq` and `Array`. Same rule.

Pipe stages with `|>`. `List.concat (List.map f xs)` is `List.concat_map f xs`.

## `fold_right` is not "map, but keep order"

`List.fold_right (fun x acc -> … x :: acc) xs []` is `map` / `filter` /
`filter_map`. `fold_right` is a right fold. It is not tail-recursive. Do not
reach for it to cons in original order.

`List.fold_left (fun acc x -> … x :: acc) [] xs` plus `List.rev` is the same
smell: a list rebuild written as a reduction.

Forbidden:

```ocaml
List.fold_right
  (fun t acc -> if t.done then acc else task_card t :: acc)
  f.tasks []
```

Required:

```ocaml
features
|> List.concat_map (fun f -> f.tasks)
|> List.filter (fun t -> not t.done)
|> List.map task_card
```

A recursive helper that conses matches and `List.rev`s at the base case is
the same shape. Write `filter` then `map`.

## When a fold is a fold

Use `List.fold_left` when the accumulator is **not** "the input, transformed
into a list": a count, a sum, a `Map`/`Set`, a record of buckets filled in
one pass.

`List.fold_right` only when the operator is inherently right-associated
**and** the result is not a rebuilt list. Say why in a comment. That case
is rare.

## Before emitting

If the fold/rec body conses onto an accumulator, stop and use the table.
