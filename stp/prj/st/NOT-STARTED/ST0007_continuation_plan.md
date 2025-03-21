---
verblock: "21 Mar 2025:v0.1: Continuation Plan for Functional Refactoring"
stp_version: 1.0.0
status: Not Started
created: 20250321
completed: 
---
# ST0007: Functional Elixir Codebase Improvements - Phase 2

## Overview

This steel thread continues the work started in ST0005, focusing on the next set of priority improvements for applying functional programming principles to the Arca.Cli codebase. Building on the foundation established with improved error handling and function decomposition, this phase will implement context-passing functions, telemetry integration, and further refactoring of medium-priority modules.

## Status: Not Started

## Objectives

1. **Implement Context-Passing Functions**:
   - Add pipeline-friendly functions with the `with_x` naming convention
   - Create context structs for maintaining state across operations
   - Refactor key pipelines to use the context-passing pattern

2. **Add Telemetry Integration**:
   - Instrument key operations with telemetry spans
   - Add rich metadata to telemetry events
   - Create telemetry handlers for common monitoring needs

3. **Refactor Medium-Priority Modules**:
   - Apply established patterns to `Arca.Cli.Command.BaseCommand`
   - Refactor `Arca.Cli.History` module to use the new error handling approach
   - Improve the `Arca.Cli.Configurator.Coordinator` with more pipeline-oriented transformations

4. **Enhance Type Specifications**:
   - Add detailed type aliases for common data structures
   - Complete missing type specifications in medium-priority modules
   - Ensure consistent use of the `result(t)` type for functions that can fail

## Implementation Plan

### Phase 1: Context-Passing Functions

1. **Define Context Structures**:
   - Create a `CommandContext` struct to hold command execution state
   - Define type specifications for the context structures
   - Add helper functions for creating and updating contexts

2. **Implement Core Context-Passing Functions**:
   - Add `with_settings/1` to load settings into a context
   - Add `with_command_handler/2` to locate and add a command handler to the context
   - Add `with_executed_command/1` to execute the command and store results in the context

3. **Refactor Command Execution Flow**:
   - Update `Arca.Cli.handle_subcommand/4` to use the context-passing pattern
   - Refactor the command execution pipeline in `main/1` to use contexts
   - Ensure backward compatibility with existing command implementations

### Phase 2: Telemetry Integration

1. **Set Up Telemetry Structure**:
   - Define standard event names and structures
   - Add telemetry dependencies if not already present
   - Create helper functions for telemetry execution

2. **Instrument Key Operations**:
   - Add telemetry spans to command execution
   - Instrument configuration loading and saving
   - Add telemetry to history operations

3. **Create Default Handlers**:
   - Implement logging handlers for telemetry events
   - Add debug output handlers for development
   - Create test utilities for verifying telemetry events

### Phase 3: Medium-Priority Module Refactoring

1. **Command Base Module**:
   - Update to use the standardized error handling approach
   - Add comprehensive type specifications
   - Implement telemetry for command creation and execution

2. **History Module**:
   - Refactor to use the new error tuple format
   - Add telemetry spans for history operations
   - Implement context-passing variants for history functions

3. **Configurator Coordinator**:
   - Refactor to use more pipeline-friendly transformations
   - Improve error handling with standardized error types
   - Add telemetry for configuration operations

### Phase 4: Documentation and Testing

1. **Update Documentation**:
   - Document new context-passing functions
   - Add examples of telemetry integration
   - Update module documentation with the new patterns

2. **Enhance Tests**:
   - Add tests for context-passing functions
   - Create telemetry testing utilities
   - Update existing tests for the refactored modules

## Success Criteria

1. All refactored modules pass existing tests
2. New functions have comprehensive test coverage
3. Documentation is updated to reflect the new patterns
4. Performance is maintained or improved
5. Code is more maintainable and follows established functional patterns

## Timeline

1. **Week 1**: Context-Passing Functions implementation
2. **Week 2**: Telemetry Integration
3. **Week 3**: Medium-Priority Module Refactoring
4. **Week 4**: Documentation, Testing, and Review

## Dependencies

- Successfully completed ST0005 refactoring (Railway-Oriented Programming)
- Existing test suite for validating refactored modules
- Style guide for consistent implementation patterns

## Next Steps

1. Begin with implementing the core context structures
2. Develop the first set of context-passing functions
3. Test these functions with the existing command flow
4. Proceed with telemetry integration once context-passing is complete