# Org Intelligence Platform (OIP)

## Project Overview
Salesforce AI application providing intelligent org insights and automation capabilities.

## Tech Stack
- Salesforce DX (source-driven development)
- Apex (triggers, batch, queueable, future methods)
- Lightning Web Components (LWC)
- SOQL/SOSL with selective queries
- Einstein AI / External AI API integrations

## Development Conventions

### Apex
- Bulkify all triggers — collect IDs/records before loops, query/DML outside loops
- Use `Database.update(scope, false)` for partial success patterns
- Implement proper error handling via `System.Savepoint` and rollback where needed
- Use async processing (Batch, Queueable, Future) for long-running operations
- Always use `@TestSetup` for test data and cover 90%+ code coverage

### LWC
- Use `@api`, `@track`, `@wire` decorators appropriately
- Follow Salesforce Lightning Design System (SLDS) for styling
- Handle loading, error, and empty states in every component

### SOQL
- Use indexed fields in WHERE clauses (Id, Name, RecordTypeId, etc.)
- Leverage relationship queries to avoid extra round-trips
- Apply LIMIT and selective filters for performance

## Scratch Org Management
- Default DevHub: health-mvp-dev (krishnendu.bose.71c3f5093136@agentforce.com)
- Scratch org definition: config/project-scratch-def.json

## Commands
- `sf org login device --alias oip-dev` — authenticate
- `sf org create scratch --definition-file config/project-scratch-def.json --alias oip-scratch --duration-days 30`
- `sf project deploy start` — deploy source to org
- `sf project retrieve start` — retrieve source from org
- `sf apex run --file scripts/apex/hello.apex` — run anonymous Apex
