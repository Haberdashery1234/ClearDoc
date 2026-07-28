//
//  ClearDoc.swift
//  ClearDoc
//
//  Created by Christian Grise on 7/25/26.
//

import Foundation

// MARK: - Purpose
// Module-level overview. ClearDoc is a small, domain-agnostic on-device
// text-clarification library built on Apple's Foundation Models framework.
// Given a block of free text, it returns a structured, plain-language
// breakdown (summary, key points, flagged terms, category) — entirely
// on-device, no network call.
//
// This package is intentionally kept generic — it doesn't know anything
// about symptoms, ICD-10 codes, or any specific consuming app. Domain-
// specific framing (e.g. instructions tuned for a particular use case)
// belongs in the consuming app's own adapter layer, not here. That's what
// keeps ClearDoc reusable across more than one project — SymptomSense is
// the first consumer, not the only one it's designed for.

// MARK: - What to implement
// - TODO: Decide whether this file should stay purely documentation (no
//   code at all) or hold a single public namespace/enum if you want a
//   central place for shared constants (e.g. a default max input length).
//   Not required — most of the real surface area lives in Analysis/ and
//   Models/.

// MARK: - Public API surface (what consumers of this package will use)
// - `ClearDocAnalyzer` (Analysis/ClearDocAnalyzer.swift) — the entry point;
//   call `analyze(_:)` with raw text, get back a `ClearDocSummary`.
// - `ClearDocSummary` / `ClearDocCategory` (Models/) — the structured
//   result type.
// - `ClearDocAvailability` (Analysis/ClearDocAvailability.swift) — check
//   before calling `analyze(_:)` so callers can show a fallback UI.

