# Phase 1 — Requirement Gathering

## Overview

Phase 1 focuses on analyzing the project's specification and converting its contents into structured, traceable information. The goal is to help the RTL agent and engineering team understand what the system is expected to do before moving to design and implementation.

The phase captures the system overview, functional requirements, interfaces and signals, operations and behavior, constraints and assumptions, verification requirements, open questions, and traceability information. It also identifies the high-level architecture.

## Current output: revision 3 (`spec_version` 1.2)

This folder holds the current Phase 1 output for the ALU assignment. Later phases read these files directly.

| File | Deliverable | IDs |
| --- | --- | --- |
| `ALU_Project_Overview_Mapping.md` | 1. Project overview | |
| `ALU_Functional_Requirements.csv` | 2. Functional requirements | FR-001 to FR-013 |
| `ALU_Interfaces_and_Signals.csv` | 3. Interfaces and signals | IF-001 to IF-016 |
| `ALU_Operation_Behavior_Table.csv` | 4. Operation / behavior table | OP-001 to OP-014 |
| `ALU_Constraints_and_Assumptions.csv` | 5. Constraints and assumptions | CA-001 to CA-018 |
| `ALU_Verification_Requirements.csv` | 6. Verification requirements | TC-001 to TC-028 |
| `ALU_Open_Questions.csv` | 7. Open questions, each answered by a decision | Q-001 to Q-018 |
| `ALU_Traceability.csv` | 8. Traceability | TR-001 to TR-108 |
| `ALU_Architecture_Corrected.svg`, `.png` | 9. High-level architecture | |
| `ALU_Design_Decisions.csv` | 10. Design decisions: answers to the open questions, with approval status | D-001 to D-018 |
| `ALU_Golden_Vectors.csv` | 11. Golden vectors: exact expected results, including boundary cases | vectors 1 to 37 |
| `alu_spec.json` | 12. Machine-readable spec: the same content with `spec_version` (read this first) | |
| `REVISION_2.md` | what revision 2 changed from revision 1, and why | |
| `REVISION_3.md` | revision 3: D-001..D-018 approved, D-014 names `CPU.svh` | |

Revision 1, in which all 18 questions are still open, is kept in git history at commit `1463e78`.

## Answering questions from later phases

When a later phase finds a gap, it writes a `questions_for_phase1.md` file in its own folder, with one numbered question per gap. Phase 1 answers each question by updating the files in this folder. It keeps the existing IDs, adds new IDs for new items, and updates `spec_version` in `alu_spec.json`. Later phases then read the updated files; they do not copy them.

## Objectives

- Understand the system described by the source specification.
- Extract requirements and system details into consistent, identifiable records.
- Capture interfaces, signals, operations, and expected behavior.
- Separate explicitly stated facts from assumptions and agent-proposed analysis.
- Identify missing, ambiguous, or contradictory information that requires clarification.
- Define candidate verification checks and link them to the requirements they address.
- Preserve references to the source document so extracted information can be reviewed.

## Inputs

The main input is the original system specification. Depending on the project, this may be provided as a PDF or Markdown document. The specification is the source of truth for extracted information.

## Activities and Deliverables

### 1. Project Overview

**Format:** PDF or Markdown (`.pdf`, `.md`)

Provides a concise description of the system based on the specification.

Fields captured:
- Project name
- Project purpose
- System description
- System components
- Scope
- Out of scope, when explicitly stated

### 2. Functional Requirements

**Format:** CSV (`.csv`)

Converts descriptions of required system behavior into individually identifiable requirements.

Fields captured:
- Requirement ID
- Requirement title
- Requirement description
- Inputs and their types, when specified
- Outputs and their types, when specified
- Expected behavior
- Preconditions, when specified
- Postconditions, when specified
- Priority, only when defined by the source

Requirement IDs should remain stable where possible. When a specification changes, existing requirements should be matched to the updated content rather than assigned new IDs unnecessarily.

### 3. Interfaces and Signals

**Format:** CSV (`.csv`)

Records how components communicate. For RTL projects, this includes ports and signals; for software specifications, it may include function parameters, return values, APIs, and component interfaces.

Fields captured:
- Interface ID
- Interface name
- Interface type
- Direction
- Data type
- Width, when relevant and specified
- Description
- Source component
- Destination component
- Constraints, including explicit ranges, valid values, or timing constraints

### 4. Operation / Behavior Table

**Format:** CSV (`.csv`)

Standardizes operations described by the specification, particularly opcodes, commands, modes, state transitions, and conditional behavior. This information can support later implementation planning and test generation.

Fields captured:
- Operation ID
- Operation name
- Operation code, when specified
- Preconditions
- Inputs
- Expected result
- Special conditions, such as carry, borrow, overflow, or boundary conditions
- Exceptions or unsupported-operation behavior, when defined

### 5. Constraints and Assumptions

**Format:** Structured table or equivalent structured output

Records system boundaries and distinguishes explicit specification rules from assumptions introduced during analysis.

Fields captured:
- Item ID
- Category: constraint, explicit assumption, proposed assumption, or limitation
- Description
- Scope
- Source, when applicable
- Impact if the item is incorrect
- Approval status: pending, approved, rejected, or not applicable

Each item should be recorded separately rather than combining all constraints and assumptions into one paragraph.

### 6. Verification Requirements

**Format:** Structured table or equivalent structured output

Defines candidate checks derived from functional requirements, interfaces, and operation tables. Acceptance criteria stated in the source should be extracted directly. If a criterion is proposed by the agent because the specification does not provide one, it must be labeled as proposed.

Fields captured:
- Test ID
- Related requirement IDs
- Test objective
- Preconditions
- Test inputs
- Expected result
- Test type, such as functional, boundary, negative, or integration
- Acceptance criteria
- Derivation status: specified or agent-proposed

These records describe verification requirements and candidate scenarios; they do not by themselves prove that tests have been implemented or executed.

### 7. Open Questions

**Format:** Suitable for tracking in Jira or Notion

Lists information that is missing, ambiguous, contradictory, or necessary before implementation can proceed safely.

Fields captured:
- Question ID
- Question
- Reason clarification is needed
- Related requirement IDs
- Source reference
- Impact if unresolved
- Suggested owner, if known
- Status: open, answered, or deferred
- Answer or resolution
- Assignee

### 8. Traceability

**Format:** Structured table or equivalent structured output

Links extracted facts and derived records back to their original source. Traceability should cover requirements, interfaces, operations, verification scenarios, and open questions as applicable.

Fields captured:
- Trace ID
- Item ID
- Item type
- Source document
- Page, when available
- Section or heading, when available
- Supporting excerpt or faithful paraphrase
- Extraction status: directly extracted, derived, or unresolved
- Optional confidence value

Traceability helps reviewers verify the source and distinguish directly stated information from derived analysis.

### 9. High-Level Architecture

Produces a high-level view of the system and its main components and relationships. The exact diagram content depends on the information available in the specification.

### 10. Design Decisions

**Format:** CSV (`.csv`)

Gives one proposed answer for each open question so later phases do not have to guess. A decision is treated as a requirement only after it is approved.

Fields captured:
- Decision ID
- Question it resolves
- Proposed decision
- Status: proposed or approved
- Approved by
- Date

### 11. Golden Vectors

**Format:** CSV (`.csv`), also embedded in `alu_spec.json`

Lists exact expected results for each operation, including boundary cases such as wrap-around, carry and borrow, shift amounts of 0 and 32, and rotation across the sign bit. The values are computed by a reference model rather than written by hand, and Phase 3 checks the design against them.

Fields captured:
- Vector number
- Operation and code
- Operands A and B
- Carry in
- Expected result, in decimal and hex
- Expected carry, or `unchanged` for operations that do not update it
- Note describing the case

### 12. Machine-Readable Spec

**Format:** JSON (`alu_spec.json`)

Holds the same content as the CSVs in a typed form that later phases read first. It contains:
- `spec_version`: increased whenever Phase 1 changes the spec, for example when it answers a question from a later phase
- `package`: package name, file, and include order
- `types`: the opcode enum, its codes, and the invalid codes
- `data_semantics`: integer width, wrap-around, and shift rules
- `classes`: properties, method signatures, and the requirements and decisions they come from
- `operations`: the semantics of each opcode and whether it updates carry
- `test_program`: what the test program must cover and its pass criterion
- `golden_vectors`: the vectors from deliverable 11
- `tool_gate`: the simulator and checks the design must pass

## Recommended Output Strategy

The structured output is stored in JSON (`alu_spec.json`), and the human-readable deliverables present the same content.

- **JSON — structured output:** Stores the sections, fixed fields, identifiers, statuses, and source references. It can be validated and passed to later agents.
- **CSV / Excel — review tables:** Allows engineers to inspect and review requirements, interfaces, operations, and verification records.
- **PDF / Markdown — readable report:** Presents the project overview and analysis in a format suitable for engineers, supervisors, and stakeholders.
- **Jira / Notion — question tracking:** Supports assignment and resolution of open questions.
- **PlantUML / draw.io — architecture diagrams:** Supports documenting the high-level architecture.

The exact export formats may vary according to the implementation and the needs of the team.

## Tools

| Tool | Intended use |
| --- | --- |
| Excel | Review and manage tabular deliverables |
| Notion or Jira | Track open questions and their resolution |
| PlantUML | Describe diagrams using text |
| draw.io | Create or edit architecture diagrams |
| JSON | Represent structured output for validation and downstream processing |
| CSV | Export individual tabular deliverables |
| PDF or Markdown | Present the project overview and readable analysis report |

## Phase Completion Criteria

Phase 1 can be considered ready for review when:

- The project overview is documented from the source specification.
- Functional requirements have unique, stable identifiers where possible.
- Relevant interfaces, signals, and operations have been captured.
- Constraints and assumptions are recorded and categorized.
- Candidate verification scenarios are linked to related requirements and clearly marked as specified or proposed.
- Missing or ambiguous information is recorded as open questions.
- Every open question has a design decision, and each decision is approved, with Approved by and Date filled in.
- The golden vectors and `alu_spec.json` agree with the approved decisions.
- Extracted and derived items have source references wherever available.
- A high-level architecture view is prepared when the specification provides sufficient information.
- The outputs are available in the agreed formats and are ready for engineering review.

Completion of this phase means the requirements analysis is organized and reviewable. It does not mean that the RTL design, verification environment, or implementation has been completed.

## Expected Outcome

At the end of Phase 1, the team should have a structured understanding of the system, a set of identifiable requirements and interfaces, documented operations and constraints, candidate verification checks, a list of unresolved questions, traceability to the original specification, and a high-level architecture view. These outputs provide a foundation for the next project phases.
