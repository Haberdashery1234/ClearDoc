# ``ClearDoc``

A domain-agnostic, on-device text-clarification library built on Apple's
Foundation Models framework.

## Overview

Given a block of free text, ``ClearDocAnalyzer`` returns a structured,
plain-language breakdown — summary, key points, flagged terms, and a
coarse category — entirely on-device, with no network call. The package
is deliberately generic: it has no knowledge of any specific consuming
app's domain. That framing belongs in each consumer's own adapter layer.

### Checking availability first

Foundation Models isn't guaranteed to be usable — the device might be
ineligible, Apple Intelligence might be off, or the model might still be
downloading. Check ``ClearDocAvailability`` before showing a "clarify"
action at all, rather than showing it and letting a call fail:

```swift
switch ClearDocAvailability.current() {
case .available:
    // show the action
case .unavailable(let reason):
    // reason is already a human-readable string, safe to show directly
}
```

### Analyzing text

Create one ``ClearDocAnalyzer`` and hold on to it — for example as `@State`
in a SwiftUI view — rather than constructing a fresh one per call, so
`prewarm()` has a chance to actually help:

```swift
@State private var analyzer = ClearDocAnalyzer()

func clarify(_ text: String) async throws -> ClearDocSummary {
    try await analyzer.analyze(text)
}
```

Call ``ClearDocAnalyzer/reset()`` between unrelated documents if you're
reusing one analyzer across the app — it rebuilds the underlying session
with the same instructions and re-prewarms it, which avoids earlier
content bleeding into later analyses and keeps the small on-device context
window from filling up with unrelated history.

For a progressive UI, ``ClearDocAnalyzer/analyzeStream(_:)`` yields
partially-filled-in snapshots as the model generates them, instead of
waiting for the whole result:

```swift
for try await partial in try analyzer.analyzeStream(text) {
    // partial.title, partial.plainLanguageSummary, etc. start out nil
    // and fill in progressively, in the order ClearDocSummary declares them.
}
```

### Handling errors

`analyze(_:)` and `analyzeStream(_:)` can throw two different kinds of
error: ``ClearDocAnalyzer/ClearDocError``, which this framework raises
itself for pre-flight validation failures (``ClearDocAnalyzer/ClearDocError/emptyInput``,
``ClearDocAnalyzer/ClearDocError/inputTooLong``) or truly unexpected
failures (``ClearDocAnalyzer/ClearDocError/generationFailed(underlying:)``);
and `LanguageModelSession.GenerationError`, Apple's own error type, passed
through unwrapped so callers can branch on it directly. Text that reads
like actual clinical/diagnostic reasoning can trip Apple's on-device safety
guardrail and throw `.refusal` — this was observed directly while building
this framework, not just documented behavior, and there's no supported way
to disable or loosen the guardrail from app code.

### Testing against ClearDoc

Code that depends on ``ClearDocAnalyzer`` doesn't have to depend on the
concrete type — ``ClearDocAnalyzing`` is a protocol mirroring its public
API, so a consuming app's own tests can substitute a fake that returns
canned results or throws specific errors on demand, without invoking the
real on-device model.

## Topics

### Entry point

- ``ClearDocAnalyzer``
- ``ClearDocAnalyzing``
- ``ClearDocAvailability``

### Result types

- ``ClearDocSummary``
- ``ClearDocCategory``