# JQL Grammar Specification

## Purpose
Defines the JUDO Query Language (JQL) syntax via an Xtext grammar (`JqlDsl.xtext`). The grammar specifies expression types, operator precedence, literal formats, navigation, and function calls that compose the JQL DSL.

## Architecture
The grammar file (`model/src/main/java/hu/blackbelt/judo/meta/jql/JqlDsl.xtext`) generates an ANTLR parser, EMF Ecore metamodel, and supporting infrastructure via Xtext. The grammar uses `hidden(SL_COMMENT, ML_COMMENT, WS)` to hide whitespace and comments. It imports `http://www.eclipse.org/emf/2002/Ecore` and generates the `jqldsl` package at `http://www.blackbelt.hu/judo/meta/jql/JqlDsl`.

Key AST node types generated from the grammar:
- `JqlExpression` — base interface for all expressions
- `BinaryOperation` — two-operand operations with `leftOperand`, `operator`, `rightOperand`
- `UnaryOperation` — single-operand operations with `operator`, `operand`
- `TernaryOperation` — conditional with `condition`, `thenExpression`, `elseExpression`
- `NavigationExpression` — property traversal with `base`, `features`, `qName`, `enumValue`
- `FunctionedExpression` — expression with attached `FunctionCall`
- `FunctionCall` — function invocation with `function` name, `parameters`, optional `lambdaArgument`
- `Feature` — navigation step (`.`, `->`, `=>`) with `name`
- `QualifiedName` — namespaced identifier with `namespaceElements` and `name`
- `SpawnOperation` — type casting with `operand` and `type`
- Literals: `BooleanLiteral`, `IntegerLiteral`, `DecimalLiteral`, `StringLiteral`, `DateLiteral`, `TimestampLiteral`, `TimeLiteral`, `MeasuredLiteral`

## Requirements

### Requirement: Operator precedence SHALL follow defined hierarchy
The grammar SHALL enforce operator precedence from lowest to highest: ternary (`?:`), `implies`, `or`, `xor`, `and`, equality (`==`, `!=`), relational (`<`, `>`, `<=`, `>=`), additive (`+`, `-`), multiplicative (`*`, `/`, `div`, `mod`), exponent (`^`), spawn (`as`), unary (`not`, `-`, `+`), function call (`!`), navigation (`.`, `->`, `=>`).

#### Scenario: Multiplication binds tighter than addition
- **GIVEN** the expression `1 + 2 * 3`
- **WHEN** parsed
- **THEN** the AST represents `1 + (2 * 3)` — the root is `BinaryOperation` with operator `+`, and `rightOperand` is a `BinaryOperation` with operator `*`

#### Scenario: Ternary is right-associative
- **GIVEN** the expression `a ? b : c ? d : e`
- **WHEN** parsed
- **THEN** the `elseExpression` of the outer ternary is itself a `TernaryOperation`

### Requirement: Boolean literals SHALL parse correctly
The grammar SHALL recognize `true` and `false` as `BooleanLiteral` nodes.

#### Scenario: Parse true literal
- **WHEN** `true` is parsed
- **THEN** the result is a `BooleanLiteral` with `isTrue` set to `true`

#### Scenario: Parse false literal
- **WHEN** `false` is parsed
- **THEN** the result is a `BooleanLiteral` with `isTrue` set to `false`

### Requirement: Numeric literals SHALL support integers and decimals
The grammar SHALL parse integer sequences as `IntegerLiteral` (returning `EBigInteger`) and dot-separated sequences as `DecimalLiteral` (returning `EBigDecimal`).

#### Scenario: Parse integer
- **WHEN** `42` is parsed
- **THEN** the result is an `IntegerLiteral` with value `42`

#### Scenario: Parse decimal
- **WHEN** `3.14` is parsed
- **THEN** the result is a `DecimalLiteral` with value `3.14`

### Requirement: String literals SHALL support single and double quotes with escaping
The grammar SHALL accept strings delimited by `"` or `'` with backslash escape sequences.

#### Scenario: Double-quoted string
- **WHEN** `"hello world"` is parsed
- **THEN** the result is a `StringLiteral` with value `hello world`

#### Scenario: Escaped quote in string
- **WHEN** `"say \"hi\""` is parsed
- **THEN** the result is a `StringLiteral` with value `say "hi"`

### Requirement: Temporal literals SHALL use backtick notation
Dates SHALL match `` `YYYY-MM-DD` ``, timestamps SHALL match `` `YYYY-MM-DDThh:mm[:ss[.fff]][Z|±hh[:mm]]` ``, and times SHALL match `` `hh:mm[:ss[.fff]]` ``.

#### Scenario: Parse date literal
- **WHEN** `` `2024-01-15` `` is parsed
- **THEN** the result is a `DateLiteral`

#### Scenario: Parse timestamp with timezone
- **WHEN** `` `2024-01-15T10:30:00+01:00` `` is parsed
- **THEN** the result is a `TimestampLiteral`

#### Scenario: Parse time literal
- **WHEN** `` `10:30` `` is parsed
- **THEN** the result is a `TimeLiteral`

### Requirement: Measured literals SHALL combine a number with a unit in square brackets
The grammar SHALL parse `NumberLiteral MEASURE_NAME` as a `MeasuredLiteral`, where `MEASURE_NAME` is a terminal matching `[...]`.

#### Scenario: Parse measured literal
- **WHEN** `10 [kg]` is parsed
- **THEN** the result is a `MeasuredLiteral` with value `10` and measure `kg`

### Requirement: Navigation SHALL support dot, arrow, and fat-arrow operators
Features SHALL use `.` (property access), `->` (collection navigation), or `=>` (container navigation).

#### Scenario: Dot navigation
- **WHEN** `self.name` is parsed
- **THEN** the result is a `NavigationExpression` with a `Feature` having `.` separator

#### Scenario: Arrow navigation
- **WHEN** `self->items` is parsed
- **THEN** the result is a `NavigationExpression` with a `Feature` having `->` separator

### Requirement: Qualified names SHALL support namespace separators
`QualifiedName` SHALL support `::` as a namespace separator, allowing patterns like `demo::model::Person`.

#### Scenario: Namespaced qualified name
- **WHEN** `demo::model::Person` is parsed
- **THEN** the `QualifiedName` has `namespaceElements` `[demo, model]` and `name` `Person`

### Requirement: Enum values SHALL use hash notation
The grammar SHALL parse `QualifiedName#EnumValue` to reference enumeration members.

#### Scenario: Enum literal
- **WHEN** `Days#MONDAY` is parsed
- **THEN** the `NavigationExpression` has `enumValue` set to `MONDAY`

### Requirement: Function calls SHALL use bang notation
Functions SHALL be invoked with `!functionName(params)` syntax, supporting optional lambda arguments with `|` separator.

#### Scenario: Function call with parameters
- **WHEN** `items!filter(x | x.active == true)` is parsed
- **THEN** the `FunctionCall` has name `filter`, `lambdaArgument` `x`, and one parameter

### Requirement: Spawn operation SHALL use 'as' keyword
The `SpawnOperation` SHALL cast an expression to a type using `expression as QualifiedName`.

#### Scenario: Type cast
- **WHEN** `entity as demo::model::SpecialEntity` is parsed
- **THEN** the result is a `SpawnOperation` with the target type qualified name

### Requirement: Comments SHALL be hidden from the AST
Single-line (`//`) and multi-line (`/* */`) comments SHALL be treated as hidden tokens.

#### Scenario: Expression with comment
- **GIVEN** the input `42 // answer`
- **WHEN** parsed
- **THEN** the result is an `IntegerLiteral` with value `42` (comment is ignored)
