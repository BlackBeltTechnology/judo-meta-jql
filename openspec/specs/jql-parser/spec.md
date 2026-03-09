# JQL Parser Specification

## Purpose
Provides the `JqlParser` runtime API for parsing JQL expressions from strings, files, and streams into an EMF-based AST (`JqlExpression`). This is the primary programmatic entry point for JQL processing outside of Eclipse.

## Architecture
`JqlParser` (`hu.blackbelt.judo.meta.jql.runtime`) uses Xtext's standalone setup to initialize a Guice injector that provides `XtextResourceSet` and `IResourceFactory` instances. The injector is lazily initialized as a thread-safe singleton. Parsed expressions are returned as deep copies (`EcoreUtil.copy`) detached from the Xtext resource.

Supporting classes:
- `JqlParseException` — wraps EMF `Diagnostic` errors from failed parses
- `JqlTerminalConverters` — Guice-bound `@Singleton` that converts terminal tokens (IDs with backslash escaping, backtick-wrapped temporal values, square-bracket measure names)
- `JqlDslStandaloneSetup` — triggers Xtext injector creation and EMF registration
- `JqlDslRuntimeModule` — Guice module binding `JqlTerminalConverters` as `IValueConverterService`

Content type constant: `JQLSCRIPT_CONTENT_TYPE = "jql"`

## Requirements

### Requirement: JqlParser SHALL parse JQL strings into JqlExpression ASTs
`parseString(String)` and `parseString(String, URI)` SHALL return a `JqlExpression` representing the root of the parsed AST, or throw `JqlParseException` if the input contains syntax errors.

#### Scenario: Parse valid expression string
- **GIVEN** a `JqlParser` instance
- **WHEN** `parseString("self.quantity * self.unitPrice * (1 - self.discount)")` is called
- **THEN** a `BinaryOperation` is returned representing the multiplication chain

#### Scenario: Parse invalid expression string
- **GIVEN** a `JqlParser` instance
- **WHEN** `parseString("self.quantity *")` is called
- **THEN** a `JqlParseException` is thrown with non-empty `getErrors()` list

#### Scenario: Parse null string
- **GIVEN** a `JqlParser` instance
- **WHEN** `parseString(null)` is called
- **THEN** `null` is returned

### Requirement: JqlParser SHALL parse JQL from files
`parseFile(File)` SHALL load and parse a `.jql` or `.psmjql` file, returning the root `JqlExpression`.

#### Scenario: Parse file
- **GIVEN** a file `sample.jql` containing `self.quantity * self.unitPrice * (1 - self.discount)`
- **WHEN** `parseFile(file)` is called
- **THEN** a `JqlExpression` is returned

### Requirement: JqlParser SHALL parse JQL from input streams
`parseStream(InputStream)` and `parseStream(InputStream, URI)` SHALL parse JQL from an arbitrary input stream.

#### Scenario: Parse stream
- **GIVEN** a `ByteArrayInputStream` containing `1 + 2`
- **WHEN** `parseStream(stream)` is called
- **THEN** a `BinaryOperation` with operator `+` is returned

### Requirement: Load methods SHALL return XtextResource for advanced access
`loadJqlFromFile`, `loadJqlFromStream`, and `loadJqlFromString` SHALL return `XtextResource` objects that provide access to diagnostics, validation, and serialization.

#### Scenario: Load and inspect resource
- **GIVEN** a JQL string `"true"`
- **WHEN** `loadJqlFromString("true", uri)` is called
- **THEN** the returned `XtextResource` contains a `BooleanLiteral` in its contents

### Requirement: Parsed expressions SHALL be detached copies
All `parse*` methods SHALL return deep copies (via `EcoreUtil.copy`) that are independent of the Xtext resource lifecycle.

#### Scenario: Expression independence
- **GIVEN** a parsed expression from `parseString("42")`
- **WHEN** the parser's internal resources are garbage collected
- **THEN** the returned `JqlExpression` remains valid and accessible

### Requirement: Xtext injector SHALL be initialized lazily and thread-safely
The static `injector()` method SHALL use synchronized lazy initialization to create the Xtext injector exactly once, registering `IResourceFactory` for content type `"jql"`.

#### Scenario: Concurrent parser creation
- **GIVEN** multiple threads creating `JqlParser` instances
- **WHEN** they all call `parseString` concurrently
- **THEN** exactly one Xtext injector is created (no duplicate initialization)

### Requirement: JqlTerminalConverters SHALL handle ID escaping
IDs prefixed with `\` SHALL have the backslash stripped during parsing, and IDs matching reserved keywords SHALL be re-escaped with `\` during serialization.

#### Scenario: Escaped identifier
- **WHEN** `\true` is parsed as an ID
- **THEN** the resulting ID value is `true` (backslash removed)

### Requirement: JqlTerminalConverters SHALL handle temporal literal formatting
Date, timestamp, and time converters SHALL strip surrounding backticks during parsing and re-add them during serialization.

#### Scenario: Date conversion
- **WHEN** the terminal `` `2024-01-15` `` is converted
- **THEN** the semantic value is `2024-01-15` (without backticks)

### Requirement: JqlTerminalConverters SHALL handle measure name formatting
The measure name converter SHALL strip surrounding square brackets during parsing and re-add them during serialization.

#### Scenario: Measure name conversion
- **WHEN** the terminal `[kg]` is converted
- **THEN** the semantic value is `kg` (without brackets)
