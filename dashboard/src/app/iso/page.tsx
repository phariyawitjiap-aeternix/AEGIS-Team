"use client";
import { Header } from "@/components/layout/Header";
import { useState, useEffect } from "react";

interface IsoDoc {
  name: string;
  path: string;
}

export default function IsoPage() {
  const [docs, setDocs] = useState<IsoDoc[]>([]);
  const [selectedDoc, setSelectedDoc] = useState<string | null>(null);
  const [content, setContent] = useState<string | null>(null);

  useEffect(() => {
    // Hardcoded list since we know the ISO doc structure
    const knownDocs = [
      "PM.01-Project-Plan",
      "PM.02-Progress-Status",
      "PM.03-Correction-Register",
      "PM.04-Backup-Record",
      "SI.01-Requirement-Specification",
      "SI.02-Design-Document",
      "SI.03-Traceability-Record",
      "SI.04-Test-Cases",
      "SI.05-Test-Report",
      "SI.06-Software-Configuration",
      "SI.07-Maintenance-Document",
    ].map((name) => ({ name, path: name }));
    setDocs(knownDocs);
  }, []);

  const handleSelect = async (docName: string) => {
    setSelectedDoc(docName);
    setContent("Loading...");
    try {
      // Try reading from the API by checking known file patterns
      const res = await fetch(
        `/api/specs?file=../iso-docs/${docName}.md`
      );
      if (res.ok) {
        const json = await res.json();
        setContent(json.data || "Document not yet created");
      } else {
        setContent("Document not yet created");
      }
    } catch {
      setContent("Could not load document");
    }
  };

  return (
    <div>
      <Header title="ISO 29110 Compliance" />
      <div className="p-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Document list */}
          <div className="lg:col-span-1 space-y-2">
            <div className="text-xs text-[var(--text-secondary)] mb-3 uppercase tracking-wider">
              Documents
            </div>
            {docs.map((doc) => (
              <button
                key={doc.name}
                onClick={() => handleSelect(doc.name)}
                className={`w-full text-left rounded-lg border p-3 text-sm transition-colors ${
                  selectedDoc === doc.name
                    ? "border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]"
                    : "border-[var(--border)] bg-[var(--bg-surface)] text-[var(--text-primary)] hover:border-[var(--accent)]/30"
                }`}
              >
                {doc.name}
              </button>
            ))}
          </div>

          {/* Content */}
          <div className="lg:col-span-2 rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6 min-h-[400px]">
            {content ? (
              <pre className="text-sm text-[var(--text-primary)] whitespace-pre-wrap font-mono leading-relaxed">
                {content}
              </pre>
            ) : (
              <div className="text-center text-[var(--text-secondary)] py-20">
                Select a document from the list
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
