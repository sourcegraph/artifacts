# Artifacts

This repository houses public artifacts from Sourcegraph.

* GraphQL Schemas

* Database migrations

After every successful release. we have a number of steps that happen during the finalization. These steps include (but are not limited to):

- Generation of SBOM
- Slack announcements
- Changelog Generation

With the new artifact export, we'll now be exporting **graphql schemas** to a public GCS bucket alongside **database migrations**. 

## Artefact export schedule

- **GraphQL schemas** are exported on every release.
- **Database schemas** are exported on every major and minor releases

You can read more about the process [here](https://www.notion.so/sourcegraph/How-the-artifacts-exporter-works-12aa8e112658809cb785eff2e0830740?pvs=4).