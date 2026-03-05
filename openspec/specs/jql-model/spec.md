# JQL Model Specification

## Purpose
Provides the EMF Ecore metamodel for JQL, including generated Java interfaces and implementation classes for all AST node types, plus model loading and resource support utilities.

## Architecture
The model is generated from the Xtext grammar via MWE2 workflow (`model/src/workflow/generateModel.mwe2`). Key packages:
- `hu.blackbelt.judo.meta.jql.jqldsl` — generated interfaces for AST nodes
- `hu.blackbelt.judo.meta.jql.jqldsl.impl` — generated implementation classes
- `hu.blackbelt.judo.meta.jql.jqldsl.util` — `JqldslResourceImpl` (XMI resource), `JqldslResourceFactoryImpl` (resource factory)
- `hu.blackbelt.judo.meta.jql.jqldsl.runtime` — `JqlDslModel` (model container), `JqlDslModelResourceSupport` (builder pattern)
- `hu.blackbelt.judo.meta.jql.jqldsl.support` — generated builder/helper classes

The model is serialized as XMI and can be loaded standalone or within OSGi.

## Requirements

### Requirement: JqlDslModel SHALL load models from files and streams
`JqlDslModel.loadJqlDslModel()` SHALL accept `LoadArguments` built via `jqlDslLoadArgumentsBuilder()` and load a JQL model from an input stream or URI.

#### Scenario: Load model from XMI file
- **GIVEN** an XMI file containing a serialized JQL expression AST
- **WHEN** `JqlDslModel.loadJqlDslModel(LoadArguments.jqlDslLoadArgumentsBuilder().inputStream(stream).name("test").build())` is called
- **THEN** a `JqlDslModel` instance is returned containing the loaded expressions

### Requirement: JqlDslModelResourceSupport SHALL provide builder-based model creation
`JqlDslModelResourceSupportBuilder` SHALL allow programmatic creation of JQL models using the builder pattern.

#### Scenario: Create model programmatically
- **WHEN** `JqlDslModelResourceSupport.jqlDslModelResourceSupportBuilder().build()` is called
- **THEN** a resource support instance is returned that can hold JQL expressions

### Requirement: XMI serialization SHALL preserve expression structure
Saving a `JqlExpression` to XMI and reloading it SHALL produce an equivalent AST.

#### Scenario: Round-trip serialization
- **GIVEN** a parsed `JqlExpression` from `parseString("1 + 2")`
- **WHEN** saved to XMI and reloaded via `JqlDslModel.loadJqlDslModel()`
- **THEN** the loaded expression is a `BinaryOperation` with operator `+`

### Requirement: Generated interfaces SHALL expose all grammar attributes
Each generated AST node interface SHALL provide getters/setters for all attributes and references defined in the grammar.

#### Scenario: BinaryOperation attributes
- **GIVEN** a `BinaryOperation` instance
- **THEN** it provides `getLeftOperand()`, `getRightOperand()`, `getOperator()`, and setters for each

#### Scenario: NavigationExpression attributes
- **GIVEN** a `NavigationExpression` instance
- **THEN** it provides `getBase()`, `getFeatures()` (EList), `getQName()`, `getEnumValue()`

#### Scenario: FunctionCall attributes
- **GIVEN** a `FunctionCall` instance
- **THEN** it provides `getFunction()` (JqlFunction with name), `getParameters()` (EList of FunctionParameter), `getLambdaArgument()`
