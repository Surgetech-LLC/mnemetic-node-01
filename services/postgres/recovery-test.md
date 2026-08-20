# PostgreSQL Recovery Validation

Date: 2026-08-20

## Objective

Validate that Mnemetic Node 01 can recover PostgreSQL application data from a logical backup after destructive data loss.

## Procedure

1. Created a PostgreSQL logical backup using `pg_dump`.
2. Verified the backup contained the `lab_validation` test record.
3. Dropped the `lab_validation` table from the running database.
4. Verified the table no longer existed.
5. Restored the database from the SQL backup.
6. Queried the restored table.

## Result

Recovery succeeded.

The restored database contained the original record:

`Mnemetic Node 01 persistence test`

## Operational Finding

PostgreSQL data can be recovered independently of the running container using the documented backup and restore workflow.

Generated backup archives are excluded from Git and remain local.
