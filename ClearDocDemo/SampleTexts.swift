//
//  SampleTexts.swift
//  ClearDocDemo
//
//  Created by Christian Grise on 7/26/26.
//

import Foundation

/// Canned, fictional sample inputs for exercising `ClearDocAnalyzer` without
/// retyping test text every run.
///
/// This lives only in the `ClearDocDemo` target — it is not part of the
/// `ClearDoc` framework product, so none of this sample content ships to
/// anything that consumes the framework.
enum SampleText: String, CaseIterable, Identifiable {
    case personalHealthNote
    case clinicalNote
    case businessRecap
    case legalNotice
    case sparseInput

    var id: String { rawValue }

    /// Short label for use in UI (e.g. quick-fill buttons).
    var label: String {
        switch self {
        case .personalHealthNote: return "Personal health note"
        case .clinicalNote: return "Clinical note"
        case .businessRecap: return "Business recap"
        case .legalNotice: return "Legal notice"
        case .sparseInput: return "Sparse input"
        }
    }

    /// The fictional sample text to feed into `ClearDocAnalyzer.analyze(_:)`.
    var text: String {
        switch self {
        case .personalHealthNote:
            return "Woke up around 3am with a sharp pain on my right side, kind of under the ribs. Took some ibuprofen around 4. Also been feeling really tired the past few days and my ankles look a little swollen. Should probably mention this at my next appointment."
        case .clinicalNote:
            return "Patient presents with a 3-day history of intermittent epigastric pain radiating to the back, associated with nausea and one episode of vomiting. Denies fever or jaundice. Physical exam notable for mild tenderness in the right upper quadrant without rebound or guarding. Plan: obtain CBC, lipase, and abdominal ultrasound to evaluate for cholelithiasis vs pancreatitis."
        case .businessRecap:
            return "Quarterly planning meeting recap: the team agreed to push the Q3 launch back two weeks to accommodate additional QA time. Marketing will hold off on the campaign announcement until the new date is confirmed. Action items: engineering to send updated timeline by Friday, marketing to draft revised messaging, finance to review budget impact of the delay."
        case .legalNotice:
            return "This notice confirms that your lease will not be renewed at the end of the current term. You are required to vacate the premises no later than the last day of the month following expiration. Any personal property left behind after that date may be disposed of in accordance with local ordinance."
        case .sparseInput:
            return "Head hurts a bit. Slept badly."
        }
    }
}
