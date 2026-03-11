# judo-meta-jql - Project Documentation

## Project Overview


**Repository:** BlackBeltTechnology/judo-meta-psm-jql
**License:** Eclipse Public License 2.0 (EPL-2.0)
**Java Version:** 21
**Build System:** Maven 3.9.4 with Tycho 4.0.13 (Eclipse plugin packaging)

1. **JQL metamodel** — Defines the JUDO Query Language (JQL), an Xtext-based DSL that lets modelers describe queries declaratively without manual implementation
2. **Parser runtime** — Provides `JqlParser`, a standalone Java API for parsing JQL expressions from strings, files, or streams into an EMF-based AST
3. **EMF code generation** — Uses Xtext grammar and MWE2 workflows to generate Ecore metamodel classes, serializers, validators, and scoping providers
4. **OSGi integration** — Repackages the model as an OSGi bundle with a `BundleTracker` that discovers and registers JQL models from other bundles at runtime
5. **Eclipse IDE tooling** — Provides editor support including syntax highlighting, content assist, outline view, and quick fixes for `.jql` and `.psmjql` files

## Code Instructions

1. First think through the problem, read the codebase for relevant files.
2. Before you make any major changes, check in with me and I will verify the plan.
3. Please every step of the way just give me a high level explanation of what changes you made.
4. Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
5. Maintain a documentation file that describes how the architecture of the app works inside and out.
6. Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
7. For implementation use TDD (Test-Driven Development): write or update tests first to define the expected behaviour, verify they fail, then write the minimal implementation to make them pass.
8. Use DRY (Don't Repeat Yourself): extract reusable logic into separate classes, utilities, or components. If the same pattern appears in multiple places, refactor it into a shared helper.

## Directory Structure

```
judo-meta-jql/
├── model/              # Core Xtext grammar, EMF model, parser runtime (eclipse-plugin)
├── model-test/         # JUnit 5 tests for parser, grammar, and model loading
├── osgi/               # OSGi bundle wrapper for non-Eclipse environments
├── osgi-itest/         # Pax Exam integration tests with Karaf
├── ide/                # Eclipse IDE support (parent)
│   ├── ide-common/     # Language Server Protocol support
│   └── ui/             # Eclipse editor, content assist, outline, quick fixes
├── feature/            # Eclipse feature packaging
├── site/               # P2 update site for Eclipse installation
├── docs/               # AsciiDoc documentation
├── .github/            # GitHub Actions workflows, issue templates
├── .mvn/               # Maven wrapper config, JVM settings
└── pom.xml             # Root POM (multi-module aggregator)
```

## Core Modules

### DSL & Parser

| Module | Type | Purpose |
|--------|------|---------|
| `model/` | eclipse-plugin | Xtext grammar (`JqlDsl.xtext`), EMF Ecore model, generated Java classes, `JqlParser` runtime, `JqlTerminalConverters` for value conversion |
| `model-test/` | jar | JUnit 5 tests — `JqlDslParserTest` (parser API), `JqlDslGrammarTest` (grammar validation), `JqlDslModelLoaderTest` (XMI loading), `JqlDslExecutionContextTest` (builder pattern) |

### OSGi Integration

| Module | Type | Purpose |
|--------|------|---------|
| `osgi/` | bundle | Repackages model with Apache Felix Bundle Plugin; exports all `hu.blackbelt.judo.meta.jql.*` packages; includes `JqlDslModelBundleTracker` for discovering bundles with `JqlDsl-Models` manifest header |
| `osgi-itest/` | jar | Pax Exam tests verifying bundle loading in Apache Karaf 4.4.7 container |

### Eclipse IDE

| Module | Type | Purpose |
|--------|------|---------|
| `ide/ide-common/` | eclipse-plugin | `JqlDslIdeSetup` — Language Server Protocol initialization via Guice |
| `ide/ui/` | eclipse-plugin | Eclipse UI integration — `JqlDslProposalProvider` (content assist), `JqlDslOutlineTreeProvider` (outline), `JqlDslLabelProvider` (labels/icons), `JqlDslQuickfixProvider` (quick fixes) |
| `feature/` | eclipse-feature | Eclipse feature descriptor for plugin installation |
| `site/` | eclipse-repository | P2 update site with version-specific URLs |

## Technology Stack

### Core Technologies
- **Xtext 2.39.0** — Grammar definition, parser generation, validation, scoping, formatting
- **Eclipse EMF** — Ecore metamodel, code generation, XMI serialization (EMF Common 2.30+, Ecore 2.21+)
- **Google Guice** — Dependency injection (Xtext runtime modules)
- **ANTLR 3.2.0** — Parser generated from Xtext grammar
- **Xtend** — Used in IDE modules for editor providers and runtime module customization

### Build & Quality
- **Maven 3.9.4** with Maven Wrapper (`./mvnw`)
- **Tycho 4.0.13** — Eclipse plugin packaging, P2 site generation, version management
- **JUnit 5** — Unit testing with Xtext testing support
- **Pax Exam** — OSGi integration testing in Karaf container
- **JaCoCo 0.8.12** — Code coverage
- **SonarQube** — Static analysis
- **Lombok 1.18.34** — Annotation processing (non-Eclipse modules only)
- **SLF4J 2.0.16** / **Logback 1.5.12** — Logging

## Build Commands

All builds use the Maven Wrapper (`./mvnw`) for consistency:

```bash
# Full build (all modules)
./mvnw clean install

# Run all tests
./mvnw clean test

# Run model tests only
./mvnw clean test -pl model-test

# Run a single test class
./mvnw clean test -pl model-test -Dtest=JqlDslParserTest

# Run a single test method
./mvnw clean test -pl model-test -Dtest=JqlDslParserTest#testMethodName

# Skip modules (build root only)
./mvnw clean install -DskipModules=true

# Update Eclipse site category versions
./mvnw clean install -P update-category-versions -f site/pom.xml
```

### Maven Profiles

| Profile | Purpose |
|---------|---------|
| `modules` | Default — builds all 8 submodules (active unless `skipModules=true`) |
| `sign-artifacts` | Signs artifacts with `sign-maven-plugin` for release |
| `release-dummy` | Deploys to local `/tmp/` directory for testing |
| `release-judong` | Deploys to JudoNG Nexus (`nexus.judo.technology`) |
| `release-central` | Deploys to Maven Central via Sonatype OSSRH |
| `generate-github-asciidoc-diagrams` | Generates PlantUML diagrams from AsciiDoc files |
| `update-source-code-license` | Updates license headers in source files |

## Key Configuration Files

| File | Purpose |
|------|---------|
| `pom.xml` | Root POM — module aggregation, dependency management, plugin configuration |
| `.mvn/jvm.config` | JVM settings: 1-2GB heap, UTF-8, `--add-opens` flags for Java module access |
| `.mvn/extensions.xml` | Maven wagon extensions for P2 repository resolution |
| `logback-test.xml` | Shared Logback configuration for test logging |
| `model/META-INF/MANIFEST.MF` | OSGi manifest — exports, imports, bundle metadata |
| `model/src/main/java/hu/blackbelt/judo/meta/jql/JqlDsl.xtext` | Xtext grammar defining JQL syntax |
| `model/src/workflow/generateModel.mwe2` | MWE2 workflow for Ecore/Xtext code generation |

## Development Environment

**Required:**
- Java 21 JDK
- Maven 3.9.4+ (or use `./mvnw`)

**For Eclipse IDE development:**
- Eclipse with m2e and Modeling Tools plugins
- XTend, XText, MWE, MWE2 features installed

**Generated code (do not edit manually):**
- `model/src/main/xtext-gen/` — Xtext-generated parser, serializer, services
- `ide/ide-common/xtend-gen/` — Generated Xtend IDE module
- `ide/ui/xtend-gen/` — Generated Xtend UI components

## Git Workflow

- **Main Branch:** `develop`
- **Versioning:** `1.0.4-SNAPSHOT` (semantic versioning; Eclipse uses `.qualifier` equivalent)
- **Branching:** GitFlow — `develop`, `feature/JNG-*`, `bugfix/JNG-*`, `release/*`, `master`
- **Commit Rule:** Every commit must include a JIRA ticket number (`JNG-xxx`)
- **CI/CD:** GitHub Actions — build, merge-pr, release, and master-release workflows
- **Releases:** Deployed to JudoNG Nexus (snapshots) or Maven Central (releases)

## Important Notes

1. **Xtext grammar is the source of truth** — the grammar file (`JqlDsl.xtext`) drives all code generation. Changes to the grammar require re-running the MWE2 workflow.
2. **Tycho version management** — Maven SNAPSHOT versions are automatically mapped to Eclipse `.qualifier` format during builds. Do not manually set Eclipse versions.
3. **No Lombok in Eclipse modules** — Tycho does not support Lombok; all source in `model/`, `ide/`, and `feature/` modules is either hand-written or generated.
4. **OSGi bundle discovery** — The `osgi` module's `JqlDslModelBundleTracker` looks for bundles with a `JqlDsl-Models` manifest header (format: `name=modelName;file=path/to/model.xmi`).
5. **JVM configuration matters** — The `.mvn/jvm.config` file includes critical `--add-opens` flags. Without these, the build will fail on Java 21.
6. **File extensions** — JQL files use `.jql` or `.psmjql` extensions, registered in the Xtext grammar.

## Related Documentation

- [README.md](README.md) — Project introduction, architecture overview, and quick API examples
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development setup, project structure, build commands, and troubleshooting
- [.github/CIFLOW.md](.github/CIFLOW.md) — Branching strategy, version numbering, and CI/CD pipeline diagrams
