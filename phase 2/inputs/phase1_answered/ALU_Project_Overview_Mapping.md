# 1. Project Overview

**Purpose:** Give the reader a concise understanding of the system described by the specification.

| Field | What the agent should fill in | ALU Assignment Mapping |
|---|---|---|
| **Project name** | The name explicitly stated in the document | **ALU Class Hierarchy and CPU Integration** *(descriptive name; the assignment does not explicitly provide a formal project name).* |
| **Project purpose** | The problem the system is intended to solve | Define a SystemVerilog class hierarchy for an Arithmetic Logic Unit (ALU), separating arithmetic and logical operations into derived classes, and integrate them through a CPU class. |
| **System description** | A short explanation of what the system does | The design uses a common `base_alu` class to store operands, the operation code, and the result. `logical_alu` and `arithmetic_alu` extend this base class to implement their respective operations. A `CPU` class contains instances of both ALU classes and provides `Reset` and `Calc` methods. A simple test program imports the package and tests the CPU and its objects. |
| **System components** | The main modules, classes, or subsystems mentioned | - `base_alu`: common properties and methods, including `operand_A`, `operand_B`, `alu_op`, `alu_result`, `display`, `load_operand_A`, `load_operand_B`, and `initialize`.<br>- `logical_alu`: derived class for AND, OR, XOR, shifts, and rotations.<br>- `arithmetic_alu`: derived class for selecting, incrementing, decrementing, addition, and subtraction operations.<br>- `CPU`: contains `logical_alu l_alu` and `arithmetic_alu a_alu`; provides `Reset` and `Calc`.<br>- `cpu_pkg`: package containing the CPU-related definitions.<br>- Test program: imports `cpu_pkg` and tests the CPU and objects.<br>- Separate source files: each class is to be placed in its own file. |
| **Scope** | What the specification explicitly includes | - Implement the `base_alu`, `logical_alu`, and `arithmetic_alu` class hierarchy.<br>- Define the properties and common methods listed for `base_alu`.<br>- Support the specified arithmetic operation codes `4'b0000` through `4'b0110` and logical operation codes `4'b0111` through `4'b1101`.<br>- Implement the `CPU` class with `Reset` and `Calc(in1, in2, operation)` returning `Result`.<br>- Put CPU definitions in a `cpu_pkg` package.<br>- Keep each class in a separate file and provide a simple test program.<br>- Use `extern` declarations for class functions if desired; this is optional in the assignment. |
| **Out of scope** | What the document explicitly excludes, if stated | **Not specified.** The assignment does not explicitly identify excluded features or define a formal out-of-scope list. Details such as invalid-opcode handling, carry/borrow conventions, shift/rotation amounts, and operand widths are not fully specified and should be recorded as open questions rather than treated as excluded. |

## Source-grounding notes

- The assignment explicitly describes the class hierarchy, ALU operations, CPU methods, package, separate class files, and test program.
- The project name above is a descriptive label, not a title quoted from the assignment.
- Where the assignment leaves behavior undefined, this mapping marks it as unspecified instead of inventing a requirement.
