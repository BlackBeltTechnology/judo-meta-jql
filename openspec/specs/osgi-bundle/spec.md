# OSGi Bundle Specification

## Purpose
Repackages the JQL model as an OSGi bundle and provides automatic discovery and registration of JQL models from other bundles via the `JqlDslModelBundleTracker`.

## Architecture
The `osgi` module uses the Apache Felix Maven Bundle Plugin to create an OSGi bundle that exports all `hu.blackbelt.judo.meta.jql.*` packages. The bundle includes model files from `../model/model` at the path `meta/jql`.

Key class: `JqlDslModelBundleTracker` (`hu.blackbelt.judo.meta.jql.osgi`) — an OSGi Declarative Services `@Component(immediate = true)` that:
1. On activation, registers a `BundleCallback` with `BundleTrackerManager`
2. Filters bundles using `JqlDslBundlePredicate` (checks for `JqlDsl-Models` manifest header)
3. On bundle match, `JqlDslRegisterCallback` parses the header, loads models, and registers `JqlDslModel` services
4. On bundle removal, `JqlDslUnregisterCallback` unregisters services and cleans up

Manifest header format: `JqlDsl-Models: name=<modelName>;file=<path/to/model.xmi>[, ...]`

Internal state:
- `Map<String, ServiceRegistration<JqlDslModel>> jqlModelRegistrations` — active service registrations
- `Map<String, JqlDslModel> jqlModels` — loaded model cache

## Requirements

### Requirement: Bundle SHALL export all JQL packages
The OSGi bundle SHALL export all `hu.blackbelt.judo.meta.jql.*` packages with the project version.

#### Scenario: Package export
- **GIVEN** the OSGi bundle is installed
- **WHEN** another bundle imports `hu.blackbelt.judo.meta.jql.runtime`
- **THEN** the import resolves successfully

### Requirement: BundleTracker SHALL discover bundles with JqlDsl-Models header
`JqlDslBundlePredicate` SHALL return `true` for bundles whose manifest contains the `JqlDsl-Models` header.

#### Scenario: Bundle with JQL model header
- **GIVEN** a bundle with manifest header `JqlDsl-Models: name=testModel;file=model/test.xmi`
- **WHEN** the bundle is installed
- **THEN** `JqlDslBundlePredicate.test()` returns `true`

#### Scenario: Bundle without JQL model header
- **GIVEN** a bundle without `JqlDsl-Models` header
- **WHEN** the bundle is installed
- **THEN** `JqlDslBundlePredicate.test()` returns `false`

### Requirement: Register callback SHALL load and register JqlDslModel services
When a matching bundle is found, `JqlDslRegisterCallback` SHALL parse the header, load each model via `JqlDslModel.loadJqlDslModel()`, and register it as an OSGi service.

#### Scenario: Successful model registration
- **GIVEN** a bundle with `JqlDsl-Models: name=myModel;file=models/my.xmi`
- **WHEN** the bundle is activated
- **THEN** a `JqlDslModel` service is registered in the OSGi service registry with the model name `myModel`

#### Scenario: Duplicate model name
- **GIVEN** a model named `myModel` is already registered
- **WHEN** another bundle tries to register a model with the same name
- **THEN** an error is logged and the duplicate is not registered

### Requirement: Unregister callback SHALL clean up on bundle removal
When a matching bundle is uninstalled, `JqlDslUnregisterCallback` SHALL unregister the corresponding `JqlDslModel` services and remove them from internal maps.

#### Scenario: Bundle uninstall cleanup
- **GIVEN** a bundle with registered JQL model `myModel`
- **WHEN** the bundle is uninstalled
- **THEN** the `JqlDslModel` service registration is unregistered and removed from the internal cache

### Requirement: Component lifecycle SHALL be immediate
The `@Component(immediate = true)` annotation SHALL ensure the tracker starts as soon as the bundle activates, without waiting for service consumers.

#### Scenario: Immediate activation
- **WHEN** the osgi bundle reaches ACTIVE state
- **THEN** `JqlDslModelBundleTracker.activate()` is called and bundle tracking begins immediately
