# ``ClearDoc``

A domain-agnostic, on-device text-clarification library built on Apple's
Foundation Models framework.

## Overview

Given a block of free text, ``ClearDocAnalyzer`` returns a structured,
plain-language breakdown — summary, key points, flagged terms, and a
coarse category — entirely on-device, with no network call. The package
is deliberately generic: it has no knowledge of any specific consuming
app's domain. That framing belongs in each consumer's own adapter layer.

<!-- TODO: expand with usage examples now that the API is implemented (analyze(_:), reset(), and the LanguageModelAvailabilityProviding seam for testing ClearDocAvailability). -->

## Topics

### Entry point

- ``ClearDocAnalyzer``
- ``ClearDocAvailability``

### Result types

- ``ClearDocSummary``
- ``ClearDocCategory``