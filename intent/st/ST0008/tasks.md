# Tasks - ST0008: Orthogonalised formatting and outputting

## Progress Summary

**Overall Status**: 60% Complete (6 of 10 work packages)

- ✅ Completed: WP1 (Context Module), WP2 (Plain Renderer), WP3 (Fancy Renderer), WP4 (Output Pipeline), WP5 (Callback Integration), WP7 (Global Options) - See done.md
- 🎯 Ready to Start: WP6 (Command Execution Integration)
- ⏸️ Blocked: WP4-WP6, WP8-WP10 (waiting on dependencies)

## Remaining Work Packages

### WP6: Command Execution Integration

**Status**: Ready to Start (can be done in parallel with WP5)
**Size**: M
**Description**: Update `Arca.Cli.execute_command/5` to handle Ctx returns while maintaining backwards compatibility.

**Tasks**:

- [ ] Modify `execute_command/5` to check return type
- [ ] Add Ctx detection and rendering path
- [ ] Preserve existing behavior for string returns
- [ ] Preserve existing behavior for {:nooutput, _} tuples
- [ ] Preserve existing behavior for error tuples
- [ ] Add integration tests for all return types
- [ ] Update error handling to work with Ctx
- [ ] Ensure REPL mode compatibility

---

### WP7: Global CLI Options

**Status**: Ready to Start (independent)
**Size**: S
**Description**: Add global `--style` and `--no-ansi` options to CLI configuration.

**Tasks**:

- [ ] Add `--style` option to global Optimus configuration
- [ ] Add `--no-ansi` as alias for `--style plain`
- [ ] Pass style option through to context metadata
- [ ] Update help text generation
- [ ] Add option parsing tests
- [ ] Document new options in README
- [ ] Add examples to user guide

---

### WP8: Sample Command Migration

**Status**: Blocked (requires WP6)
**Size**: S
**Description**: Migrate `AboutCommand` to use Ctx as proof of concept and example.

**Tasks**:

- [ ] Update AboutCommand to return Ctx
- [ ] Use appropriate output types (info, list, etc.)
- [ ] Test both fancy and plain output modes
- [ ] Verify backwards compatibility
- [ ] Create migration guide based on experience
- [ ] Document patterns and best practices

---

### WP9: Test Infrastructure Updates

**Status**: Blocked (requires WP6)
**Size**: M
**Description**: Update test helpers and fixtures to support both output styles.

**Tasks**:

- [ ] Create test helper for asserting Ctx output
- [ ] Add matcher for plain text output
- [ ] Add matcher for structured output items
- [ ] Update existing test helpers to handle Ctx
- [ ] Create fixture comparison utilities
- [ ] Add environment variable test helpers
- [ ] Document testing patterns for command authors

---

### WP10: Documentation Package

**Status**: Blocked (requires all other WPs)
**Size**: S
**Description**: Create comprehensive documentation for command authors.

**Tasks**:

- [ ] Write migration guide from string to Ctx returns
- [ ] Create output type reference documentation
- [ ] Add cookbook examples for common patterns
- [ ] Update BaseCommand documentation
- [ ] Add troubleshooting guide
- [ ] Create quick reference card
- [ ] Update README with new features

---

## Dependencies Graph

```
WP1 ✅ ──┬──> WP3 ✅ ──> WP4 ✅ ──┬──> WP5 ✅
        │                      ├──> WP6 🎯 ──┬──> WP8
WP2 ✅ ──┘                      │          └──> WP9
                               └──> WP10
WP7 ✅ (completed)
```

## Next Steps

1. **Start WP6 (Command Execution Integration)** - Update execute_command to handle Ctx returns
2. **Then WP8 (Sample Command Migration)** - Migrate AboutCommand as proof of concept
3. **Then WP9 (Test Infrastructure)** - Update test helpers for both output styles

## Success Metrics

- [ ] All existing tests pass without modification
- [ ] New commands can use Ctx with structured output
- [ ] Plain mode produces no ANSI codes
- [ ] Test fixtures work in both modes
- [ ] Performance regression < 5%
- [ ] Zero breaking changes for existing commands
- [ ] Documentation coverage for all new APIs
