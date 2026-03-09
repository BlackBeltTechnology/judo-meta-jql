# Model Test Specification

## Purpose
Validates the JQL parser, grammar, and model loading through JUnit 5 tests. Ensures all expression types parse correctly and models can be serialized/deserialized.

## Architecture
Test classes reside in `model-test/src/test/java/hu/blackbelt/judo/meta/jql/runtime/`. Test data files are in `model-test/src/test/model/`:
- `sample.jql` — contains `self.quantity * self.unitPrice * (1 - self.discount)`
- `sample.psmjql` — alternative file extension test data
- `test.jql.xmi` — serialized JQL model for loader tests

Test classes:
- `JqlDslParserTest` — tests `JqlParser` API methods (file, stream, string loading)
- `JqlDslGrammarTest` (Xtend) — comprehensive grammar validation with 25+ test methods
- `JqlDslModelLoaderTest` — tests XMI model loading via `JqlDslModel`
- `JqlDslExecutionContextTest` — tests builder-based model creation via `JqlDslModelResourceSupport`

## Requirements

### Requirement: Parser API tests SHALL verify all loading methods
`JqlDslParserTest` SHALL test `loadJqlFromFile`, `loadJqlFromStream`, `loadJqlFromString`, `parseFile`, `parseStream`, and `parseString`.

#### Scenario: Load and parse from file
- **GIVEN** `src/test/model/sample.jql` exists
- **WHEN** `loadJqlFromFile` and `parseFile` are called
- **THEN** a valid `XtextResource` and `JqlExpression` are returned respectively

#### Scenario: Load and parse from string
- **GIVEN** the expression `self.quantity * self.unitPrice * (1 - self.discount)`
- **WHEN** `loadJqlFromString` and `parseString` are called
- **THEN** the result is a `BinaryOperation`

### Requirement: Grammar tests SHALL cover all expression types
`JqlDslGrammarTest` SHALL test string literals, boolean literals, numeric literals, arithmetic operations, unary expressions, ternary expressions, logical precedence, date/time/timestamp literals, measured literals, navigation, relational operations, parenthesized expressions, function calls, enum literals, and qualified name navigation.

#### Scenario: Arithmetic operations
- **WHEN** expressions like `1+2`, `1*2`, `1/2`, `1 div 2`, `1 mod 2`, `2^3` are parsed
- **THEN** each produces a `BinaryOperation` with the correct operator

#### Scenario: Logical precedence
- **WHEN** `a or b and c xor d implies e` is parsed
- **THEN** the AST reflects correct precedence: `implies` at root, then `or`, then `and`, then `xor`

#### Scenario: Measured literals with qualified units
- **WHEN** `0.1[model::Mass#mg]` is parsed
- **THEN** the result is a `MeasuredLiteral` with decimal value `0.1` and measure `model::Mass#mg`

### Requirement: Model loader tests SHALL verify XMI deserialization
`JqlDslModelLoaderTest` SHALL load `test.jql.xmi` and verify the model structure.

#### Scenario: Load XMI model
- **GIVEN** `src/test/model/test.jql.xmi` exists
- **WHEN** `JqlDslModel.loadJqlDslModel()` is called with the file
- **THEN** a valid `JqlDslModel` instance is returned

### Requirement: Execution context tests SHALL verify builder pattern
`JqlDslExecutionContextTest` SHALL create a model using `JqlDslModelResourceSupport.jqlDslModelResourceSupportBuilder()`.

#### Scenario: Builder-based model creation
- **WHEN** `jqlDslModelResourceSupportBuilder().build()` is called
- **THEN** a valid resource support instance is created
