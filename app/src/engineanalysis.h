#pragma once

#include <QStringView>
#include <QVariantList>

namespace EngineAnalysis {

struct Batch {
    QVariantList candidates;
    QVariantList ownership;
};

// Parse one complete kata-analyze line without transport or session state.
// Missing/invalid fields are omitted, while valid candidate segments survive.
// A consumer replaces its live batch only when candidates is nonempty; an
// empty ownership list then clears ownership from the preceding batch.
Batch parseInfoLine(QStringView line);

}
