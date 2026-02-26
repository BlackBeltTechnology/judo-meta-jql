# Eclipse Packaging Specification

## Purpose
Packages the JQL model and IDE support as Eclipse features and a P2 update site for installation into Eclipse IDE.

## Architecture
Two modules handle Eclipse distribution:

**feature/** (`eclipse-feature` packaging):
- `feature.xml` defines feature `hu.blackbelt.judo.meta.jql.feature` ("Judo Jql Model Feature")
- Includes plugin: `hu.blackbelt.judo.meta.jql.model`
- Requires: `org.eclipse.emf.ecore`, `org.eclipse.xtext` (2.16+), `org.antlr.runtime` (3.2+), `org.eclipse.xtend.lib` (2.14+), `org.eclipse.xtext.ui`, `org.eclipse.xtext.builder`, `org.slf4j.api`, and others

**site/** (`eclipse-repository` packaging):
- `category.xml` defines four categories:
  - `jql` — "Judo Jql Model" (`hu.blackbelt.judo.meta.jql.feature`)
  - `jql_source` — "Judo Jql Model Source" (`hu.blackbelt.judo.meta.jql.feature.source`)
  - `jql_ide` — "Judo Jql IDE" (`hu.blackbelt.judo.meta.jql.ide.feature`)
  - `jql_ide_source` — "Judo Jql IDE Source" (`hu.blackbelt.judo.meta.jql.ide.feature.source`)
- Version-specific update site URLs (versions are coded in URLs, updated via `update-category-versions` profile)

## Requirements

### Requirement: Feature SHALL include the model plugin
The `hu.blackbelt.judo.meta.jql.feature` feature SHALL include the `hu.blackbelt.judo.meta.jql.model` plugin.

#### Scenario: Feature installation
- **WHEN** a user installs the "Judo Jql Model" feature from the P2 site
- **THEN** the `hu.blackbelt.judo.meta.jql.model` plugin is installed

### Requirement: Feature SHALL declare all required dependencies
The feature SHALL declare required plugins/features for EMF, Xtext, ANTLR, Xtend, SLF4J, and Eclipse UI components so that the Eclipse P2 resolver can install them automatically.

#### Scenario: Dependency resolution
- **GIVEN** an Eclipse installation without Xtext
- **WHEN** the user attempts to install the JQL feature
- **THEN** Eclipse prompts to also install the required Xtext, EMF, and other dependencies

### Requirement: Update site SHALL provide four categories
The P2 update site SHALL expose categories for model, model source, IDE, and IDE source features.

#### Scenario: Site categories
- **WHEN** a user adds the update site URL in Eclipse
- **THEN** four categories are shown: Judo Jql Model, Judo Jql Model Source, Judo Jql IDE, Judo Jql IDE Source

### Requirement: Category versions SHALL be updatable via Maven profile
Running `mvn clean install -P update-category-versions -f site/pom.xml` SHALL update version-specific URLs in the category definition.

#### Scenario: Version update
- **GIVEN** the project version has changed
- **WHEN** the `update-category-versions` profile is executed
- **THEN** the category.xml references reflect the new version numbers
