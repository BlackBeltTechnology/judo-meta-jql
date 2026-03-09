# OSGi Integration Test Specification

## Purpose
Verifies that the JQL OSGi bundle loads correctly and reaches ACTIVE state in an Apache Karaf container using Pax Exam.

## Architecture
Test classes in `osgi-itest/src/test/java/hu/blackbelt/judo/meta/jql/osgi/itest/`:
- `JqlModelLoadITest` — main integration test class (`@RunWith(PaxExam.class)`, `@ExamReactorStrategy(PerClass.class)`)
- `KarafFeatureProvider` — utility class providing Karaf container configuration, port allocation, bundle lookup, and service tracking helpers

The test provisions an Apache Karaf 4.4.7 container, installs the JQL OSGi bundle, and verifies it starts correctly. Karaf configuration includes Java module system `--add-opens` flags required for Java 21.

## Requirements

### Requirement: JQL OSGi bundle SHALL reach ACTIVE state in Karaf
`JqlModelLoadITest.testBundleActive()` SHALL verify that the `hu.blackbelt.judo.meta.jql.osgi` bundle is in `Bundle.ACTIVE` state after installation.

#### Scenario: Bundle activation
- **GIVEN** an Apache Karaf container with the JQL features installed
- **WHEN** the container starts
- **THEN** `findBundleByName(bundleContext, "hu.blackbelt.judo.meta.jql.osgi")` returns a bundle in ACTIVE state

### Requirement: Required OSGi services SHALL be available
The test SHALL inject `LogService`, `BundleTrackerManager`, and `BundleContext` via `@Inject`.

#### Scenario: Service injection
- **GIVEN** the Karaf container is running with JQL bundles
- **WHEN** services are injected
- **THEN** `LogService`, `BundleTrackerManager`, and `BundleContext` are non-null

### Requirement: Karaf configuration SHALL include Java module system flags
`KarafFeatureProvider.configureVmOptions()` SHALL add `--add-reads`, `--add-exports`, `--add-opens`, and `--patch-module` JVM arguments required for Java 9+ module system compatibility.

#### Scenario: JVM options
- **WHEN** the Karaf container is configured
- **THEN** VM options include module system flags for `java.base`, `java.xml`, and other required modules
