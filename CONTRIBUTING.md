# Contributing to Org Intelligence Platform (OIP)

This document defines the style and conventions used in this project.
All contributions should follow these rules unless otherwise noted.

## 1. General Code Style

- Favor clarity over brevity.
- Keep classes and methods small and focused on a single responsibility.
- Avoid repeating logic; prefer shared service classes and utility methods.
- Remove unused variables, imports, code paths, and files.
- All Apex classes must use `with sharing` unless explicitly justified with a comment explaining why `without sharing` is required.
- Enforce CRUD/FLS checks before any describe, query, insert, or update on custom objects and fields.
- Respect governor limits: bulkify all operations, query outside loops, DML outside loops, max 100 callouts per transaction.
- Every feature must be toggleable via `OIP_Config__mdt` records — no hard-coded feature flags.

## 2. Naming Conventions

Use descriptive names. Avoid abbreviations unless well-known in the Salesforce ecosystem (e.g., FLS, OLS, DML, SOQL).

### Apex

| Item | Convention | Example |
|---|---|---|
| Classes | `PascalCase` with `OIP_` prefix for custom classes | `OIP_DiagnosticsLogger`, `OIP_RootCauseAnalyzerService` |
| Inner Classes | `PascalCase` | `TraversalResult`, `Hypothesis` |
| Methods | `camelCase` | `traverseBFS`, `calculateConfidence`, `resolveFieldAccess` |
| Variables | `camelCase` | `componentFullName`, `healthScore`, `permSetIds` |
| Constants | `UPPER_SNAKE_CASE` with class-level `static final` | `MAX_BULK_SIZE`, `MAX_CALLOUTS` |
| Custom Objects | `OIP_` prefix + `PascalCase` + `__c` suffix | `OIP_MetadataIndex__c`, `OIP_DebugSession__c` |
| Custom Fields | `OIP_` prefix + `PascalCase` + `__c` suffix | `OIP_ComponentType__c`, `OIP_FullName__c` |
| Custom Metadata Types | `OIP_` prefix + `PascalCase` + `__mdt` suffix | `OIP_Config__mdt` |
| Custom Metadata Fields | `OIP_` prefix + `PascalCase` + `__c` suffix | `OIP_IsEnabled__c` |
| Permission Sets | `OIP_` prefix + `PascalCase` | `OIP_User`, `OIP_Admin`, `OIP_Debug`, `OIP_PHI_Access` |
| Test Classes | Match the class name + `Test` suffix | `OIP_DiagnosticsLoggerTest`, `OIP_MetadataIndexerServiceTest` |
| Triggers | Singular object name + `Trigger` | `OIP_MetadataIndexTrigger` |
| Trigger Handler Classes | Object name + `TriggerHandler` | `OIP_MetadataIndexTriggerHandler` |

### Lightning Web Components (LWC)

| Item | Convention | Example |
|---|---|---|
| Component Folder | `camelCase` with `oip` prefix | `oipDashboard`, `oipSearchBar`, `oipHealthScoreGauge` |
| HTML File | Same as folder name | `oipDashboard.html` |
| JS File | Same as folder name | `oipDashboard.js` |
| JS Class | `PascalCase` with `Oip` prefix | `OipDashboard`, `OipSearchBar` |
| Meta XML File | Same as folder name | `oipDashboard.js-meta.xml` |
| CSS File | Same as folder name | `oipDashboard.css` |
| `@api` Properties | `camelCase` | `healthScore`, `sessionId`, `componentTypes` |
| `@track` Properties | `camelCase` | `recentSessions`, `queryText` |
| Event Names | `camelCase` | `searchsubmit`, `nodeselect`, `hypothesisselect` |
| CSS Custom Properties | `--oip-kebab-case` | `--oip-health-score-green`, `--oip-severity-critical` |

### JSON Configuration

| Item | Convention | Example |
|---|---|---|
| Property Names | `camelCase` | `orgName`, `sourceApiVersion`, `packageDirectories` |
| NO trailing commas | Per `.prettierrc` | `{ "name": "org-intelligence-platform" }` |
| Double quotes | Always | As required by JSON spec |

### SOQL

| Item | Convention | Example |
|---|---|---|
| Keyword casing | UPPERCASE | `SELECT`, `FROM`, `WHERE`, `LIMIT` |
| Field references | Use custom field `__c` names with full path | `OIP_MetadataIndex__c.OIP_FullName__c` |
| Bind variables | `camelCase` with colon prefix | `:componentType`, `:permSetIds` |

## 3. Formatting Rules

### Apex

- Indentation: **4 spaces** (no tabs)
- Line length: **max 120 characters**
- Encoding: **UTF-8**, no BOM
- End files with a newline
- Align variable declarations and assignments when it improves readability
- Opening brace on the same line (`K&R style`)

```apex
// CORRECT: K&R brace style
public with sharing class OIP_DiagnosticsLogger {
    public static void log(String serviceName, String message) {
        if (String.isBlank(serviceName)) {
            return;
        }
        // method body
    }
}

// INCORRECT: Allman brace style
public with sharing class OIP_DiagnosticsLogger
{
    public static void log(String serviceName, String message)
    {
        // avoid this style
    }
}
```

### JavaScript (LWC)

- Indentation: **4 spaces** (no tabs)
- Line length: **max 120 characters**
- String quotes: **single quotes** for ordinary strings, **backtick** for template literals
- Semicolons: **always**
- Trailing commas: **none** (per `.prettierrc`)
- One space before opening brace in control flow: `if (condition) {`

```javascript
// CORRECT
import { LightningElement, wire, track } from 'lwc';
import getHealthScore from '@salesforce/apex/OIP_DashboardController.getHealthScore';

export default class OipDashboard extends LightningElement {
    @track healthScore = 0;
    @track recentSessions = [];

    @wire(getHealthScore)
    wiredHealthScore({ error, data }) {
        if (data) {
            this.healthScore = data.score;
        } else if (error) {
            this.healthScore = 0;
        }
    }
}
```

### HTML (LWC Templates)

- Indentation: **4 spaces**
- Attribute quotes: **always use double quotes**
- Self-closing tags for void elements where applicable
- One space before `>` in self-closing tags

```html
<!-- CORRECT -->
<template>
    <div class="slds-page-header">
        <h1 class="slds-page-header__title">Org Intelligence Platform</h1>
    </div>
    <c-oip-health-score-gauge score={healthScore}></c-oip-health-score-gauge>
</template>

<!-- INCORRECT -->
<template>
<div class=slds-page-header>
<h1 class=slds-page-header__title>Org Intelligence Platform</h1>
</div>
<c-oip-health-score-gauge score={healthScore} />
</template>
```

### JSON

- Indentation: **2 spaces**
- Double quotes: **always** (required by JSON spec)
- No trailing commas
- No comments (per Google JSON Style Guide)

### XML (Metadata)

- Indentation: **4 spaces**
- Attributes on separate lines for multi-attribute elements
- Self-closing tags for elements without content

```xml
<!-- CORRECT -->
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__RecordPage</target>
    </targets>
</LightningComponentBundle>
```

### CSS (LWC)

- Indentation: **2 spaces**
- Use SLDS (Salesforce Lightning Design System) classes as primary styling
- Custom CSS only when SLDS cannot achieve the requirement
- Use BEM-like naming with `oip-` prefix for custom classes

```css
/* CORRECT */
.oip-health-score-gauge {
    padding: var(--slds-g-spacing-3, 12px);
}

.oip-health-score-gauge__label {
    font-size: var(--slds-g-font-size-3, 14px);
}

.oip-health-score-gauge--critical {
    color: var(--slds-g-color-error-base, #ea001e);
}
```

## 4. Comments and Documentation

### Apex

- Every `public` and `global` method must have a Javadoc-style comment block describing purpose, parameters, and return values.
- Use `//` for single-line inline comments. Use `/* */` for multi-line inline comments.
- Comment *why*, not *what*, unless intent is unclear.
- Keep comments up-to-date as code changes.

```apex
/**
 * Traverses the dependency graph using breadth-first search starting from
 * the given node, returning all reachable nodes up to the specified depth.
 *
 * @param startNodeId The ID of the OIP_DependencyNode__c to start traversal from
 * @param maxDepth    Maximum depth to traverse (capped at 5)
 * @return            Ordered list of TraversalResult objects by depth
 */
public static List<TraversalResult> traverseBFS(Id startNodeId, Integer maxDepth) {
    // Cap depth to prevent excessive traversal
    if (maxDepth > 5) maxDepth = 5;
    ...
}
```

### JavaScript (LWC)

- Use `//` for single-line comments
- Use `/** */` for JSDoc-style documentation on `@api` properties and public methods
- No commented-out code in production

```javascript
/**
 * Handles the search submit event from oipSearchBar.
 * @param {CustomEvent} event - The searchsubmit event containing query and type.
 */
handleSearchSubmit(event) {
    const { query, type } = event.detail;
    this.performSearch(query, type);
}
```

### Recommended Comment Tags

```
TODO:     Follow-up work or planned improvements
FIXME:    Known incorrect behavior that needs fixing
NOTE:     Non-obvious design decision or important context
HACK:     Temporary workaround that should be removed later
GOVERNOR: Governor limit consideration or mitigation note
```

## 5. Salesforce-Specific Conventions

### Bulkification

Every Apex method that processes records must handle collections, not single records. SOQL and DML must never appear inside loops.

```apex
// CORRECT: Bulkified
public static void upsertIndexRecords(List<OIP_MetadataIndex__c> records) {
    for (Integer i = 0; i < Math.ceil(records.size() / MAX_BULK_SIZE.doubleValue()); i++) {
        Integer startIdx = i * MAX_BULK_SIZE;
        Integer endIdx = Math.min(startIdx + MAX_BULK_SIZE, records.size());
        Database.upsert(records.subList(startIdx, endIdx), OIP_MetadataIndex__c.OIP_CompoundKey__c, false);
    }
}

// INCORRECT: SOQL inside loop
for (String type : types) {
    List<ApexClass> classes = [SELECT Id, Name FROM ApexClass WHERE NamespacePrefix = :type];
}
```

### Error Handling

- Use `Database.insert(records, false)` and `Database.update(records, false)` for partial success patterns.
- Use `System.Savepoint` and rollback for transactional integrity where needed.
- Log all errors to `OIP_DiagnosticsLog__c` via `OIP_DiagnosticsLogger`.
- Never swallow exceptions silently.

```apex
try {
    Database.upsert(indexRecords, OIP_MetadataIndex__c.OIP_CompoundKey__c, false);
} catch (DmlException e) {
    OIP_DiagnosticsLogger.log('OIP_MetadataIndexerService', 'ERROR',
        'Upsert failed: ' + e.getMessage(), componentRef);
}
```

### CRUD/FLS Enforcement

Before any schema describe, query, DML, or field access on custom objects and fields, check accessibility:

```apex
if (!Schema.sObjectType.OIP_MetadataIndex__c.isCreateable()) {
    OIP_DiagnosticsLogger.log('OIP_MetadataIndexerService', 'WARN',
        'User lacks create access on OIP_MetadataIndex__c', null);
    return 0;
}
```

### Async Processing

- Use `Database.Batchable` for bulk processing exceeding DML/SOQL limits.
- Use `System.Queueable` for chained async operations.
- Never use `@future` when Queueable is available — Queueable supports chaining and state.
- All batch and queueable jobs must log start/finish to `OIP_DiagnosticsLog__c`.

### Test Classes

- Minimum 90% code coverage per class.
- Use `@TestSetup` for test data creation.
- Test bulk scenarios (200+ records).
- Use `Test.startTest()` and `Test.stopTest()` for async testing.
- Mock external callouts with `HttpCalloutMock`.
- Mock Tooling API with `OIP_ToolingAPIClient.isTestMode` flag pattern.

```apex
@IsTest
private class OIP_DiagnosticsLoggerTest {
    @TestSetup
    static void makeData() {
        OIP_DiagnosticsLog__c log = new OIP_DiagnosticsLog__c(
            OIP_ServiceName__c = 'TestClass',
            OIP_LogLevel__c = 'INFO',
            OIP_Message__c = 'Test message',
            OIP_Timestamp__c = Datetime.now()
        );
        insert log;
    }

    @IsTest
    static void testLogBulk() {
        List<OIP_DiagnosticsLog__c> logs = new List<OIP_DiagnosticsLog__c>();
        for (Integer i = 0; i < 200; i++) {
            logs.add(new OIP_DiagnosticsLog__c(
                OIP_ServiceName__c = 'BulkTest',
                OIP_LogLevel__c = 'DEBUG',
                OIP_Message__c = 'Bulk entry ' + i,
                OIP_Timestamp__c = Datetime.now()
            ));
        }
        Test.startTest();
        OIP_DiagnosticsLogger.logBulk(logs);
        Test.stopTest();

        List<OIP_DiagnosticsLog__c> results = [
            SELECT Id FROM OIP_DiagnosticsLog__c
            WHERE OIP_ServiceName__c = 'BulkTest'
        ];
        System.assertEquals(200, results.size(), 'Should insert 200 log entries');
    }
}
```

## 6. Permission-Aware UI Patterns

All LWC components must degrade gracefully for users without debug permissions:

```html
<template>
    <template if:true={hasOIPUserPermission}>
        <c-oip-search-bar></c-oip-search-bar>
    </template>
    <template if:false={hasOIPUserPermission}>
        <div class="slds-text-align_center slds-p-around_large">
            <p>Contact your administrator for OIP access.</p>
        </div>
    </template>
</template>
```

Apex controller guard:

```javascript
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

@wire(checkOIPUserPermission)
wiredPermission({ error, data }) {
    if (data !== undefined) {
        this.hasNoPermission = !data;
    }
}
```

## 7. Agentforce Integration Conventions

- All Agent Actions must use `@InvocableMethod` with descriptive labels.
- Prompt templates must include grounding instructions: "Do NOT invent causes not present in the grounding data."
- Every root cause response must include a confidence score (0–99, never 100).
- All grounding data must come from real org metadata via Apex service methods — no hallucinated data.

```apex
public with sharing class OIP_SymptomInterpreterAction {
    @InvocableMethod(label='Interpret OIP Symptoms' description='Parses natural language symptom descriptions into structured component references')
    public static List<SymptomResult> interpretSymptoms(List<String> queries) {
        List<SymptomResult> results = new List<SymptomResult>();
        for (String query : queries) {
            results.add(OIP_RootCauseAnalyzerService.analyzeSymptoms(query));
        }
        return results;
    }
}
```

## 8. Commit and Review Practices

### Commits

- One logical change per commit.
- Write clear commit messages following this format:

```
type(scope): short description

Optional longer explanation of context and rationale.
```

Valid types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`.

Examples:

```
feat(indexer): add Tooling API client for ApexClass index type
fix(logger): handle null componentRef in deduplication method
refactor(graph): extract BFS traversal into reusable method
test(logger): add bulk scenario test for logBulk method
chore(config): update scratch org definition with AI features
```

### Pre-commit Hooks

The project uses Husky + lint-staged (defined in `package.json`). Before each commit:

1. Prettier formats all staged `.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}` files
2. ESLint checks all staged `.{aura,lwc}/**/*.js` files
3. LWC Jest runs related tests for staged `lwc/**` files

### Reviews

- Keep pull requests reasonably small (ideally under 400 lines changed).
- Be respectful and constructive in review discussions.
- Address requested changes or explain if you disagree.
- All PRs require at least one approval before merge.

## 9. Testing

- Write tests for all new functionality.
- Minimum 90% code coverage per Apex class.
- Test bulk scenarios (200+ records) for all service methods.
- Use `@TestSetup` for test data creation.
- Tests should be deterministic — no randomness without seeding.
- Prefer readable test cases over complex test abstraction.
- Use the `OIP_ToolingAPIClient.isTestMode` pattern for mocking Tooling API in unit tests:

```apex
@IsTest
static void testWithMockToolingAPI() {
    OIP_ToolingAPIClient.isTestMode = true;
    OIP_ToolingAPIClient.testMockResults = new List<Map<String, Object>>{
        new Map<String, Object>{'Id' => '01p...', 'Name' => 'TestClass'}
    };
    // ... test service
}
```

- Run all tests before pushing:

```bash
# Apex tests
sf apex test run --test-level RunLocalTests --wait 30

# LWC tests
npm run test:unit

# Lint
npm run lint
npm run prettier:verify
```

## 10. Project Structure

```
force-app/main/default/
├── applications/          # Lightning App definitions
├── aura/                  # Aura components (avoid new ones — use LWC)
├── classes/               # Apex classes (OIP_ prefix)
│   ├── services/          # Service layer classes
│   ├── actions/            # Agentforce @InvocableMethod classes
│   ├── handlers/           # Trigger handlers
│   └── tests/              # Test classes
├── contentassets/          # Static content assets
├── flexipages/             # Lightning Page layouts
├── layouts/                # Page Layouts
├── lwc/                    # Lightning Web Components (oip prefix)
├── objects/                # Custom Objects and Fields
│   ├── OIP_MetadataIndex__c/
│   ├── OIP_DependencyNode__c/
│   ├── OIP_DependencyEdge__c/
│   ├── OIP_DebugSession__c/
│   └── OIP_DiagnosticsLog__c/
├── permissionsets/         # Permission Sets
│   ├── OIP_User.permissionset-meta.xml
│   ├── OIP_Admin.permissionset-meta.xml
│   ├── OIP_Debug.permissionset-meta.xml
│   └── OIP_PHI_Access.permissionset-meta.xml
├── staticresources/        # Static resources
├── tabs/                   # Custom Tabs
├── triggers/               # Apex Triggers (single trigger per object)
└── customMetadata/         # OIP_Config__mdt records
```

## 11. Health Cloud Extension Conventions

When `OIP_Config__mdt.Enable_PHI_Mode` is enabled:

- All PHI fields (`OIP_IsPHI__c = true`) must be redacted in debug session logs unless the user has `OIP_PHI_Access` permission.
- LWC components must check `hasPHIAccess` before rendering PHI field names or values.
- Permission tracing must include PHI compliance risk assessment.
- The `OIP_PHIWarningBanner` component must be displayed on any workspace that surfaces PHI data.

## 12. Governor Limit Reference

| Limit | Context | Threshold | Mitigation |
|---|---|---|---|
| SOQL queries | Synchronous | 100 | Batch per component type, selective WHERE |
| SOQL queries | Asynchronous | 200 | Queueable chaining |
| DML statements | Synchronous | 150 | Bulk DML in chunks of 200 |
| DML rows | Synchronous | 10,000 | `Database.insert(records, false)` for partial success |
| CPU time | Synchronous | 10s | Offload heavy processing to Batch/Queueable |
| CPU time | Asynchronous | 60s | Chained Queueable with progress tracking |
| Heap size | Synchronous | 6MB | Stream results, don't hold entire sets in memory |
| Callouts | Synchronous | 100 | Batch Tooling API calls by type, chain Queueable |
| Future calls | Synchronous | 50 | Prefer Queueable over @future |

## 13. Changes to This Guide

Style evolves. Propose improvements by opening an issue on the GitHub repository or submitting a pull request that updates this document. All proposed changes require review by at least one project maintainer.