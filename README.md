# ClearDoc

A domain-agnostic, on-device text-clarification framework for iOS 26+, built
on Apple's [Foundation Models](https://developer.apple.com/documentation/foundationmodels)
framework.

Give `ClearDocAnalyzer` a block of free text, and it returns a structured,
plain-language breakdown of it: a title, a plain-language summary, a handful
of key points, any terms worth flagging, and a coarse category. Everything
runs on-device via Guided Generation — no network call is made, and no data
leaves the device.

ClearDoc itself has no idea what kind of app is using it. It doesn't know
about symptoms, ICD-10 codes, contracts, or meeting notes — it just clarifies
text. Domain-specific framing (tone, instructions, what "clarify" means for
your use case) belongs in your app's own adapter layer on top of it. That's
what keeps it reusable: [SymptomSense](https://github.com/Haberdashery1234)
is the first consumer of ClearDoc, not the only one it's designed for.

## Why this exists

Most "AI summarize this" features either ship a network call to a hosted LLM
or don't exist at all in small apps that can't justify the infrastructure.
Foundation Models makes a third option viable: a real, structured
summarization feature that runs entirely on-device, with no server, no API
key, and no per-request cost. ClearDoc packages that pattern once so it
doesn't have to be rebuilt per app.

## Requirements

- iOS 26+ (this project currently targets `IPHONEOS_DEPLOYMENT_TARGET = 26.5`)
- Xcode 26+
- A device or Simulator with Apple Intelligence available — a physical
  device is required to exercise on-device generation for real. The
  Simulator can build and run the UI, but Foundation Models generation needs
  a real device with Apple Intelligence enabled and the model downloaded.

## Project layout

```
ClearDoc/                   The framework itself (this is the product)
  ClearDoc.swift             Module-level overview, no real code
  Analysis/
    ClearDocAnalyzer.swift    Entry point: analyze(_:), analyzeStream(_:), reset()
    ClearDocAnalyzing.swift    Protocol seam over ClearDocAnalyzer, for tests
    ClearDocAvailability.swift  Checks whether the model is usable right now
  Models/
    ClearDocSummary.swift      @Generable result type
    ClearDocCategory.swift     @Generable classification enum
  ClearDoc.docc/               DocC documentation catalog

ClearDocDemo/                Sample SwiftUI app exercising the framework
ClearDocTests/                Unit tests for the framework
ClearDocDemoTests/            Unit tests for the demo app
ClearDocDemoUITests/          UI tests for the demo app

.github/workflows/ci.yml     GitHub Actions: builds + tests both schemes
```

## Usage

```swift
import ClearDoc

// Hold on to one analyzer for the lifetime of a view/screen rather than
// creating a fresh one per call — this lets prewarming actually help.
@State private var analyzer = ClearDocAnalyzer()

func clarify(_ text: String) async {
    do {
        let summary = try await analyzer.analyze(text)
        print(summary.title)
        print(summary.plainLanguageSummary)
        print(summary.keyPoints)      // 3–6 items
        print(summary.flaggedTerms)
        print(summary.category)       // .general, .personalHealthNote, or .medical
    } catch let error as ClearDocAnalyzer.ClearDocError {
        // .emptyInput, .inputTooLong, or .generationFailed(underlying:) —
        // ClearDoc's own pre-flight validation, or a genuinely unexpected
        // failure. Conforms to LocalizedError, so error.localizedDescription
        // is already a user-facing message, safe to show directly.
    } catch let error as LanguageModelSession.GenerationError {
        // Apple's own error type, passed through unwrapped so you can branch
        // on it directly — .refusal (safety guardrail), .exceededContextWindowSize,
        // .assetsUnavailable, .unsupportedLanguageOrLocale, .rateLimited.
    }
}
```

Check availability before showing the feature at all, rather than showing it
and letting a call fail:

```swift
switch ClearDocAvailability.current() {
case .available:
    // show the "clarify" action
case .unavailable(let reason):
    // reason is already a human-readable string, safe to show directly
}
```

### Streaming

For a progressive UI, `analyzeStream(_:)` yields partial snapshots as the
model generates them instead of waiting for the whole result:

```swift
for try await partial in try analyzer.analyzeStream(text) {
    // partial.title, partial.plainLanguageSummary, etc. start out nil and
    // fill in progressively, in the order ClearDocSummary declares them.
}
```

### `ClearDocAnalyzer` is an actor

Calls to `analyze(_:)`, `analyzeStream(_:)`, and `reset()` from outside the
type are implicitly `await`-ed, since `ClearDocAnalyzer` is an `actor` —
that's what makes it safe to share one instance across concurrent calls
(e.g. a double-tapped button) without both racing to mutate the underlying
`LanguageModelSession` at once.

### Reusing vs. resetting a session

`ClearDocAnalyzer` can be used two ways, and the choice is yours depending on
what fits your app:

- **Fresh per call** — construct a new `ClearDocAnalyzer` each time you need
  to analyze something. Simplest option; each analysis is fully isolated
  from every other, at the cost of never benefiting from prewarming.
- **Shared, long-lived** — hold one instance (e.g. `@State` in a SwiftUI
  view, as in `ClearDocDemo`) and reuse it across calls to `analyze(_:)`,
  calling `await reset()` between unrelated documents. There's no reset API
  on `LanguageModelSession` itself — `reset()` rebuilds the session under
  the hood with the same instructions and re-prewarms it — so callers
  holding a shared analyzer don't need to know that detail themselves.
  Resetting between unrelated documents avoids two problems: earlier
  content bleeding into later analyses, and the small on-device context
  window (shared between prompt and response) filling up with unrelated
  history.

### Testing your own code against ClearDoc

Depend on `any ClearDocAnalyzing` instead of the concrete `ClearDocAnalyzer`
if you want to fake it out in your own tests:

```swift
struct MyViewModel {
    let analyzer: any ClearDocAnalyzing  // real ClearDocAnalyzer in the app,
                                          // a fake returning canned results in tests
}
```

### A note on the safety guardrail

Apple's on-device safety guardrail can refuse input that reads like actual
clinical/diagnostic reasoning (observed directly while building this, not
just documented behavior) — it throws
`LanguageModelSession.GenerationError.refusal`. There's no supported way to
disable or loosen the guardrail from app code. `ClearDocCategory.medical`
exists to classify this kind of content when it *does* get through, but
content written like a differential diagnosis is exactly what's most likely
to be refused outright.

## Sample app

`ClearDocDemo` is a small SwiftUI app for exercising the framework
interactively: paste or type text (or pick from a few canned fictional
samples covering a personal health note, a clinical note, a business recap,
a legal notice, and deliberately sparse input), tap Analyze, and see the
resulting `ClearDocSummary` rendered — category, title, summary, numbered
key points, and flagged terms as tags. A Reset button rebuilds the shared
analyzer's session on demand.

Run it on a device signed into Apple Intelligence to see real output; on the
Simulator or a device without Apple Intelligence, the app shows a fallback
"feature unavailable" view instead of trying and failing.

## Testing

Both `ClearDoc` and `ClearDocDemo` have shared Xcode schemes checked in, so
`xcodebuild test -scheme ClearDoc` and `xcodebuild test -scheme ClearDocDemo`
work from a clean checkout without opening the project in Xcode first.

- **`ClearDocAnalyzerValidationTests`** — pre-flight input validation
  (`.emptyInput`, `.inputTooLong`). Model-free, always runs.
- **`ClearDocAnalyzerModelTests`** — the real model-calling tests (successful
  analysis, guardrail refusal, `reset()` leaving the analyzer usable).
  **Currently disabled** via an unconditional `XCTSkip` — these consistently
  hit an environment-level `GenerationError -1 / ModelManagerError 1026`
  failure specific to this test target (the identical calls work reliably
  through the `ClearDocDemo` app), and switching from Swift Testing to
  XCTest didn't change that outcome. See the doc comment on
  `ClearDocAnalyzerModelTests` for how to re-enable them if a working
  invocation path turns up.
- **`ClearDocAvailabilityTests`** — every branch of `ClearDocAvailability`,
  exercised deterministically via a fake `LanguageModelAvailabilityProviding`
  rather than depending on the real device's actual state.
- **`ClearDocAnalyzingTests`** — confirms a fake `ClearDocAnalyzing` actually
  works as a stand-in for `ClearDocAnalyzer` in test code.
- **`ClearDocCategoryTests`** — sanity check on the case list.

## CI

`.github/workflows/ios.yml` builds and tests both schemes (`ClearDoc`,
`ClearDocDemo`) on GitHub's `macos-26` runner against an iOS Simulator, on
every push/PR to `main`. Xcode version is `latest-stable` rather than
pinned, and the simulator is picked dynamically by UDID at runtime rather
than hardcoded by name, so it isn't tied to exactly which iPhone model or
iOS point release the runner image ships. The disabled model-calling
tests report as skipped in CI, which is expected — there's no real
device, signed-in Apple Intelligence, or downloaded model available on a
CI runner regardless.

## Status

Actively developed alongside its first real consumer, SymptomSense. The
public API (`ClearDocAnalyzer`, `ClearDocAnalyzing`, `ClearDocAvailability`,
`ClearDocSummary`, `ClearDocCategory`) is implemented and documented, but
this hasn't shipped in a production app yet — treat it as a working
prototype, not a stable 1.0.
