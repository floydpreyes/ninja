# Altus POL DR Tabletop Runbook

## Purpose

This runbook is the detailed source of truth for the Altus POL disaster recovery tabletop exercise. The workbook remains the operator-facing control sheet, while this document captures the technical design, dependencies, scenario intent, and evidence expectations.

## Scope

The exercise covers the three primary Altus POL DR components:

1. Azure Data Factory in AIS: `adf-prd-ae-ais`
2. Function App in POL: `func-prd-ae-pol`
3. Logic App in POL: `logic-prd-ae-pol`

Supporting dependencies in scope:

1. DR Key Vault: `kv-prd-ae-pol`
2. Shared geo-replicated storage account: `stprdasepol`
3. APIM endpoint used by the Function App: `apim-prd-ase-ais.azure-api.net`
4. Shared production-connected dependencies such as Dataverse, SFTP shares, and external vendor flows

## Current DR Design Notes

The Altus POL DR design is partially isolated.

1. DR ADF, Function App, Logic App, Key Vault, and managed identity are regional DR assets.
2. Some downstream dependencies remain shared with production, including Altus-facing APIs and data plane integrations.
3. DR storage must use `stprdasepol`, because it is the geo-replicated account referenced by the DR ADF parameters, DR Logic App settings, and infrastructure parameters.
4. The DR Function App previously referenced `stprdaepol`. That value has been corrected to `stprdasepol` and must remain aligned before the exercise is run.

## Pre-Exercise Validation

Complete these checks before moving into recovery mode:

1. Confirm participant roster, approvals, and communications path.
2. Confirm Azure service health in Australia Southeast and Australia East.
3. Confirm DR operator access to `adf-prd-ae-ais`, `func-prd-ae-pol`, `logic-prd-ae-pol`, `kv-prd-ae-pol`, and required subscriptions/resource groups.
4. Confirm self-hosted integration runtime/network path is available for the DR data factory flows that rely on it.
5. Confirm DR storage references resolve to `stprdasepol`.
6. Confirm the following DR secrets are available in `kv-prd-ae-pol`:
   - `host--functionKey--default`
   - `apimSubscriptionKey`
   - `techone-sftp-host`
   - `techone-sftp-user`
   - `techone-sftp-private-key`

## Exercise Phases

### Phase 1: Declaration and Readiness

1. Confirm DR declaration and tabletop scope.
2. Confirm DR assets are present and accessible.
3. Confirm APIM dependency reachability from the DR Function App path.
4. Confirm storage/container/path access on `stprdasepol`.

### Phase 2: Technical Validation

#### Scenario CFG-01: DR Storage Standardisation

Goal: verify all active DR runtime and execution references use `stprdasepol`.

Evidence:

1. DR Function App settings reference `stprdasepol`
2. DR Logic App settings reference `stprdasepol`
3. DR ADF parameters reference `stprdasepol`
4. Workbook/runbook notes reflect the storage correction

#### Scenario LA-01: Inbound PROJ-FCR via DR Logic App

Goal: validate the controlled DR handling path for `F1PPM_08-Master-Data-PROJ-FCR*`.

Execution summary:

1. Prepare a controlled PROJ-FCR test file.
2. Confirm primary-region logic will not unintentionally process the file during the scenario.
3. Apply the DR-only logic filter or controlled run approach.
4. Run `TechOne_POL_FileTransfer` in `logic-prd-ae-pol`.
5. Confirm the file lands in `techone-pol/STAGE` on `stprdasepol`.

Evidence:

1. Workflow run id
2. Blob path screenshot
3. Configuration evidence for the controlled DR handling logic

#### Scenario ADF-01: FCRIMPORT in DR ADF

Goal: validate `FCRIMPORT` execution in `adf-prd-ae-ais`.

Execution summary:

1. Test linked services in DR ADF.
2. Confirm source file exists in `techone-pol/STAGE` on `stprdasepol`.
3. Prefer manual pipeline execution or isolated trigger validation.
4. Run `FCRIMPORT` and observe copy, upsert, and delete behaviour.

Evidence:

1. Pipeline run id
2. Linked service test results
3. Altus target validation
4. Source file deletion evidence

#### Scenario FA-01: TECHONE_FILES_ARCHIVE

Goal: validate the DR archive path through the Function App.

Execution summary:

1. Confirm staged files exist under `techone-pol/STAGE`.
2. Run `TECHONE_FILES_ARCHIVE` from DR ADF.
3. Confirm ADF invokes `TechOneFileArchiveProcessor` on `func-prd-ae-pol`.
4. Confirm the archive copy is created under the `archive` container.

Evidence:

1. Pipeline run id
2. Function App log entry
3. Archive container screenshot

#### Scenario APIM-01: WORKSPACE / InfloProjectUpdate

Goal: validate the DR Function App path that updates Altus through APIM.

Execution summary:

1. Confirm `kv-prd-ae-pol` resolves `apimSubscriptionKey` and the host function key.
2. Place a controlled `OCPPM_18-Projects-*` file in `inflo-pol/IMPORTS`.
3. Run `WORKSPACE` in `adf-prd-ae-ais`.
4. Confirm `InfloProjectUpdate` reads the import file and updates Altus through APIM.

Evidence:

1. Pipeline run id
2. Function App log
3. Altus update evidence
4. APIM dependency validation

#### Scenario KV-01: DR Secret Resolution

Goal: validate DR secret resolution for ADF, Function App, and Logic App dependencies.

Execution summary:

1. Test ADF linked services that depend on Key Vault.
2. Confirm DR Function App and DR Logic App settings reference `kv-prd-ae-pol` secrets.
3. Verify all required secrets can be resolved without falling back to primary-region vault references.

Evidence:

1. Linked service test screenshots
2. Application configuration evidence
3. Secret reference validation notes

### Phase 3: Business and Vendor Confirmation

1. Confirm expected file movement with application stakeholders.
2. Confirm any vendor-facing outcomes that were in scope.
3. Record blockers and decide continue, stop, or defer.

### Phase 4: Exit and Reset

1. Disable DR workflows/triggers used for the exercise.
2. Revert temporary file-specific logic or routing changes.
3. Reconfirm primary-region configuration state.
4. Verify no residual Azure, vendor, or data issues remain.
5. Record final pass/fail and remediation actions.

## Known Risks and Constraints

1. APIM remains ASE-hosted in the current design, so this exercise validates dependency reachability rather than APIM failover.
2. Some production-connected dependencies remain shared, so the tabletop must not overstate full isolation.
3. The shared scheduled trigger in ADF contains multiple pipelines, so manual or isolated execution is safer for DR validation.
4. Logic App inbound handling for PROJ-FCR should be treated as a controlled scenario, because the current repo workflow does not explicitly include that file pattern.

## Source Files

Primary repo references for this runbook:

1. `ais-azure-adf/_parameters/ais-dr-environment.json`
2. `ais-azure-adf/pipeline/FCRIMPORT.json`
3. `ais-azure-adf/pipeline/TECHONE_FILES_ARCHIVE.json`
4. `ais-azure-adf/pipeline/WORKSPACE.json`
5. `pol-azure-apps/src/Apps/Pol.Integration.FuncApp.TechOne/appsettings-dr.json`
6. `pol-azure-apps/src/Apps/Pol.Integration.FuncApp.TechOne/TechOneFileArchiveProcessor.cs`
7. `pol-azure-apps/src/Apps/Pol.Integration.FuncApp.TechOne/InfloProjectUpdate.cs`
8. `pol-azure-apps/src/Apps/Pol.Integration.LogicApp.TechOne/TechOne_POL_FileTransfer/workflow.json`
9. `pol-azure-apps/src/Apps/Pol.Integration.LogicApp.TechOne/POL_Techone_File_Transfer/workflow.json`
10. `pol-azure-infra/IT PLA DR Runsheet - Azure Integration Services.csv`
11. `pol-azure-infra/IT PLA DR Runsheet - Azure Integration Services AltusPOL.csv`