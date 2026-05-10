# Org Intelligence Platform (OIP) — Design Document

## 1. Product Vision

The Org Intelligence Platform (OIP) is a Salesforce-native debugging, diagnostics, and impact analysis tool that transforms how admins, developers, and architects understand complex orgs. Instead of manually tracing dependencies across dozens of flows, Apex classes, triggers, and custom fields, OIP provides a single intelligence layer that indexes your entire metadata graph, traces permission chains, ranks root causes for failures, and surfaces deployment blockers — all in plain English. Whether you're asking "why is this flow failing?" or "what breaks if I delete this field?", OIP delivers ranked, confident answers grounded in your actual org data, not guesswork.

Built as a managed package with a namespace (`oip`) and strict layer separation, OIP is designed for Health Cloud environments where PHI field access auditing, consent dependency tracing, and automation conflict detection are first-class concerns. The platform leverages Agentforce for natural-language interaction, Tooling API for metadata introspection, and a scheduled async indexing engine that keeps the intelligence layer fresh without exhausting governor limits. Every feature degrades gracefully for users without debug permissions, and every Apex service enforces `with sharing`, CRUD/FLS checks, and bulk-safe patterns — because this is the tool that runs your org, and it must be trustworthy.

## 2. Architecture Diagram Description

```
┌─────────────────────────────────────────────────────────────────────┐
│                        LAYER 1 — UI (LWC)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │  Search  │ │  Impact  │ │  Root    │ │ Security │ │Deployment││
│  │Workspace │ │ Analysis │ │  Cause   │ │  Debug   │ │  Debug   ││
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘│
│       │            │            │            │            │       │
│  ┌────┴─────┐ ┌────┴─────┐                                           │
│  │Automation│ │Dashboard │                                           │
│  │Conflicts │ │  (Home)  │                                           │
│  └────┬─────┘ └────┬─────┘                                           │
└───────┬──────────┬──────────┬──────────┬──────────┬────────────────┘
        │          │          │          │          │
┌───────┴──────────┴──────────┴──────────┴──────────┴────────────────┐
│                    LAYER 2 — SERVICE (Apex)                       │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │MetadataIndexer   │  │DependencyGraph   │  │RootCause       │ │
│  │Service           │  │Engine            │  │AnalyzerService │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬────────┘ │
│  ┌────────┴─────────┐  ┌───────┴──────────┐  ┌───────┴────────┐ │
│  │PermissionResolver │  │DeploymentDebugger│  │Automation      │ │
│  │Service            │  │Service           │  │ConflictDetector│ │
│  └────────┬─────────┘  └───────┬──────────┘  └───────┬────────┘ │
│  ┌────────┴─────────┐                                                   │
│  │DiagnosticsLogger │                                                   │
│  └────────┬─────────┘                                                   │
└───────────┼──────────┼──────────┼──────────┼──────────┼──────────────┘
            │          │          │          │          │
┌───────────┴──────────┴──────────┴──────────┴──────────┴──────────────┐
│                    LAYER 3 — DATA (Custom Objects & CMDT)           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │OIP_Metadata  │ │OIP_Dependency│ │OIP_Dependency│               │
│  │Index__c      │ │Node__c        │ │Edge__c       │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │OIP_Debug     │ │OIP_Diagnostics│ │OIP_Config   │               │
│  │Session__c    │ │Log__c         │ │__mdt         │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
┌──────────────────────────────────┴──────────────────────────────────┐
│                    LAYER 4 — PLATFORM APIs                        │
│  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │Tooling API │ │Metadata  │ │SOQL/SOSL │ │Agentforce        │  │
│  │(ApexClass, │ │API (deploy│ │(indexed  │ │(AI Agent Layer,  │  │
│  │ Flow, MCD, │ │ compare) │ │ search)  │ │ invocable actions│  │
│  │ SymbolTab) │ │          │ │          │ │ grounded in data) │  │
│  └────────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
│  ┌──────────────────────┐ ┌───────────────────────────────────┐  │
│  │UserEntityAccess /    │ │FieldPermissions /                  │  │
│  │EntityDefinition      │ │ObjectPermissions / Profile/PermSet │  │
│  └──────────────────────┘ └───────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

## 3. Full Data Model

### 3.1 OIP_MetadataIndex__c

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Name | Auto Number | — | Yes | `META-{0000}` |
| OIP_ComponentType__c | Picklist | — | Yes | ApexClass, Flow, LWC, Aura, Trigger, CustomField, CustomObject, ValidationRule, RecordType, Layout, PermissionSet, Profile, PageLayout, EmailTemplate, CustomMetadataType |
| OIP_FullName__c | Text | 255 | Yes | Full API name |
| OIP_NamespacePrefix__c | Text | 15 | No | Package namespace if managed |
| OIP_Label__c | Text | 255 | No | User-facing label |
| OIP_Description__c | LongTextArea | 32768 | No | Description from metadata |
| OIP_IsActive__c | Checkbox | — | Yes | Whether component is active/deployed |
| OIP_LastModifiedById__c | Lookup(User) | — | No | Last modifying user |
| OIP_LastModifiedDate__c | DateTime | — | No | Last modified timestamp |
| OIP_OwningObjectId__c | Text | 18 | No | Parent object ID |
| OIP_SourceApiVersion__c | Text | 10 | No | API version |
| OIP_Status__c | Picklist | — | Yes | Active, Deprecated, Draft, Error |
| OIP_HealthRisk__c | Picklist | — | No | None, Low, Medium, High, Critical |
| OIP_IndexedAt__c | DateTime | — | Yes | Timestamp of last indexing |
| OIP_JobRunId__c | Text | 36 | No | Async job correlation ID |
| OIP_IsPHI__c | Checkbox | — | No | Health Cloud PHI field flag |
| OIP_IsEncrypted__c | Checkbox | — | No | Platform encryption status |
| OIP_CompoundKey__c | Formula | — | — | `OIP_ComponentType__c + '||' + OIP_FullName__c` |

**Indexes:** `OIP_FullName__c`, `OIP_ComponentType__c`, `OIP_CompoundKey__c` (external ID)

### 3.2 OIP_DependencyNode__c

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Name | Auto Number | — | Yes | `NODE-{0000}` |
| OIP_MetadataIndexId__c | Lookup(OIP_MetadataIndex__c) | — | Yes | Link to indexed component |
| OIP_ComponentType__c | Picklist | — | Yes | Same picklist as MetadataIndex |
| OIP_FullName__c | Text | 255 | Yes | Denormalized for query performance |
| OIP_SeverityRating__c | Picklist | — | No | None, Low, Medium, High, Critical |
| OIP_DependencyCount__c | Number(8,0) | — | No | Outgoing dependency count |
| OIP_DependentCount__c | Number(8,0) | — | No | Incoming dependency count |
| OIP_IsRootCause__c | Checkbox | — | No | Flagged during root cause analysis |
| OIP_LastAnalyzedAt__c | DateTime | — | No | When this node was last traversed |

### 3.3 OIP_DependencyEdge__c

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Name | Auto Number | — | Yes | `EDGE-{0000}` |
| OIP_SourceNodeId__c | Lookup(OIP_DependencyNode__c) | — | Yes | Component that has the dependency |
| OIP_TargetNodeId__c | Lookup(OIP_DependencyNode__c) | — | Yes | Component being depended upon |
| OIP_EdgeType__c | Picklist | — | Yes | References, Invokes, Extends, Implements, Overrides, Calls, TriggersOn, ReadsField, WritesField, DeploymentRequires |
| OIP_Strength__c | Picklist | — | Yes | Strong, Weak |
| OIP_Description__c | Text | 500 | No | Human-readable dependency description |
| OIP_IsPotentialConflict__c | Checkbox | — | No | Flagged when overlap detected |

### 3.4 OIP_DebugSession__c

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Name | Auto Number | — | Yes | `SESSION-{0000}` |
| OIP_UserId__c | Lookup(User) | — | Yes | Who initiated the session |
| OIP_QueryText__c | LongTextArea | 32768 | Yes | Natural language query |
| OIP_SessionType__c | Picklist | — | Yes | Search, ImpactAnalysis, RootCause, SecurityDebug, DeploymentDebug, AutomationConflict |
| OIP_Status__c | Picklist | — | Yes | InProgress, Completed, Abandoned |
| OIP_SummaryFindings__c | LongTextArea | 32768 | No | AI-generated summary |
| OIP_ConfidenceScore__c | Number(3,0) | — | No | 0–100 confidence score |
| OIP_OrgHealthScoreSnapshot__c | Number(5,2) | — | No | Health score at time of session |
| OIP_StartTime__c | DateTime | — | Yes | When session started |
| OIP_EndTime__c | DateTime | — | No | When session completed |
| OIP_EducateContext__c | LongTextArea | 32768 | No | Agentforce grounding context |
| OIP_ActionsTaken__c | LongTextArea | 32768 | No | Actions user took |
| OIP_PrivacyMode__c | Picklist | — | No | Standard, PHI_Enabled |

### 3.5 OIP_DiagnosticsLog__c

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Name | Auto Number | — | Yes | `LOG-{0000}` |
| OIP_DebugSessionId__c | Lookup(OIP_DebugSession__c) | — | No | Parent session |
| OIP_LogLevel__c | Picklist | — | Yes | DEBUG, INFO, WARN, ERROR, FATAL |
| OIP_ServiceName__c | Text | 80 | Yes | Service class that produced this log |
| OIP_Message__c | LongTextArea | 32768 | Yes | Log message |
| OIP_ComponentRef__c | Text | 255 | No | FullName of relevant component |
| OIP_StackHash__c | Text | 32 | No | MD5 hash for deduplication |
| OIP_Timestamp__c | DateTime | — | Yes | When the log was created |
| OIP_Category__c | Picklist | — | No | Governor, Security, Dependency, Deployment, Automation, Performance |
| OIP_Editable__c | Checkbox | — | Yes | Whether user can annotate |

### 3.6 OIP_Config__mdt (Custom Metadata Type)

| Field Name | Type | Length | Required | Description |
|---|---|---|---|---|
| Label | Text | 80 | Yes | Human-readable config name |
| DeveloperName | — | — | Yes | API name |
| OIP_IsEnabled__c | Checkbox | — | Yes | Master switch for this feature |
| OIP_Description__c | Text | 255 | No | What this flag controls |
| OIP_DefaultValue__c | Text | 255 | No | Fallback value when IsEnabled is false |
| OIP_HealthCloudMode__c | Checkbox | — | No | Whether this config applies only in Health Cloud mode |

**Default records:** Enable_Search, Enable_Impact_Analysis, Enable_Root_Cause_Analyzer, Enable_Security_Debugging, Enable_Deployment_Debugging, Enable_Automation_Conflicts, Enable_Dashboard, Enable_PHI_Mode, Enable_Export_CSV, Enable_Export_PDF, Async_Indexing_Batch_Size, Async_Indexing_Schedule_Cron

## 4–18. [Full specification continues — see conversation history for complete sections on Apex class design, LWC component tree, Agentforce agent design, workspace UI designs, Tooling API integration, root cause engine, permission resolver, org health score, async indexing, security, testing, sprint roadmap, first 10 files, Health Cloud extension, and risks and mitigations]

---

*Sprint roadmap: 5 sprints, 2 weeks each. Sprint 1 delivers data model, DiagnosticsLogger, MetadataIndexerService, dashboard shell, health score gauge, and permission sets.*