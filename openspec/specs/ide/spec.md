# IDE Integration Specification

## Purpose
Provides Eclipse IDE and Language Server Protocol (LSP) support for JQL, including syntax highlighting, content assist, outline view, label rendering, and quick fixes for `.jql` and `.psmjql` files.

## Architecture
The IDE support is split into two sub-modules under `ide/`:

**ide-common** (Language Server Protocol):
- `JqlDslIdeModule` — Guice module extending `AbstractJqlDslIdeModule` for IDE component bindings
- `JqlDslIdeSetup` — extends `JqlDslStandaloneSetup`, creates a Guice injector mixing `JqlDslRuntimeModule` and `JqlDslIdeModule`

**ide/ui** (Eclipse-specific):
- `JqlDslUiModule` — Guice module extending `AbstractJqlDslUiModule` for Eclipse UI bindings
- `JqlDslProposalProvider` — content assist/autocomplete (extends `AbstractJqlDslProposalProvider`)
- `JqlDslLabelProvider` — object labels and icons (extends `DefaultEObjectLabelProvider`)
- `JqlDslDescriptionLabelProvider` — labels for `IEObjectDescription` and `IResourceDescription` (extends `DefaultDescriptionLabelProvider`)
- `JqlDslOutlineTreeProvider` — outline view structure (extends `DefaultOutlineTreeProvider`)
- `JqlDslQuickfixProvider` — quick fix implementations (extends `DefaultQuickfixProvider`)

All UI classes are Xtend files with generated Java output in `xtend-gen/`.

## Requirements

### Requirement: IDE setup SHALL create a properly configured Guice injector
`JqlDslIdeSetup.createInjector()` SHALL return an injector that combines runtime and IDE modules, enabling LSP functionality.

#### Scenario: LSP initialization
- **WHEN** `new JqlDslIdeSetup().createInjector()` is called
- **THEN** an injector is returned that can provide Xtext IDE services

### Requirement: Content assist SHALL be customizable
`JqlDslProposalProvider` SHALL extend the generated proposal provider, allowing custom completion proposals for JQL expressions.

#### Scenario: Content assist extension point
- **GIVEN** a JQL editor with cursor after `self.`
- **WHEN** content assist is triggered
- **THEN** the `JqlDslProposalProvider` is invoked to compute proposals

### Requirement: Label provider SHALL render AST nodes in the UI
`JqlDslLabelProvider` SHALL provide text and image representations for JQL AST nodes in Eclipse views (outline, editor hover, etc.).

#### Scenario: Label rendering
- **GIVEN** a `BinaryOperation` node in the outline
- **WHEN** the UI requests a label
- **THEN** `JqlDslLabelProvider` returns a human-readable text representation

### Requirement: Outline provider SHALL structure JQL documents
`JqlDslOutlineTreeProvider` SHALL customize how JQL document structure is displayed in the Eclipse Outline view.

#### Scenario: Outline structure
- **GIVEN** a `.jql` file is open in the editor
- **WHEN** the Outline view is shown
- **THEN** the expression tree is displayed hierarchically

### Requirement: Quick fix provider SHALL offer resolutions for validation errors
`JqlDslQuickfixProvider` SHALL provide quick fixes linked to validation issues reported by `JqlDslValidator`.

#### Scenario: Quick fix for validation error
- **GIVEN** a validation error is reported on a JQL expression
- **WHEN** the user invokes quick fix
- **THEN** `JqlDslQuickfixProvider` offers applicable resolution(s)
