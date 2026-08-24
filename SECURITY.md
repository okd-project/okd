## Reporting a Security Vulnerability or Incident

Please do not report security vulnerabilities or security incidents via public
channels such as GitHub Issues or Pull Requests. To ensure coordinated
disclosure, direct all security questions and vulnerability reports to:

- **Email**: <secalert@redhat.com>

<secalert@redhat.com> is the authoritative channel for coordinated disclosure of
OKD vulnerabilities. You may also reach the OKD community security contact at
<security@okd.io>; however, confidential vulnerability
reports should be sent to <secalert@redhat.com> to ensure proper
embargo handling.

Further details at <https://access.redhat.com/security/team/contact>

### Submission Guidelines

To help triage and resolve the issue efficiently, please include the following
in your report:

- **Title**: A concise, descriptive summary of the issue.
- **Reporter Details**: Your name or handle and affiliation.
- **Technical Description**: Detailed information regarding the vulnerability.
- **Affected Versions**: The specific version(s) or range(s) of OKD tested.
- **Reproduction Steps**: A minimal, functional example to reproduce the issue.
- **Impact Assessment**: Potential exploit scenarios and perceived severity (optional).
- **Suggested Fix**: Any proposed patches or mitigations (optional).
- **Disclosure Status**: Whether this has been shared with other parties or
  published, and your plan for future sharing (e.g., at a conference).

## Response Timeline

Email sent to <secalert@redhat.com> is read and acknowledged with a non-automated
response within **one business day**. Red Hat will work with you to confirm the
existence and impact of the vulnerability.

Red Hat prefers embargo disclosure timelines of less than **14 days**; however,
efforts will be made to keep public dates realistic.

## Vulnerability Handling Process

### Identification

1. A vulnerability is reported by a user, contributor, security researcher, or
   discovered internally via <secalert@redhat.com>.
2. Red Hat Product Security opens an investigation to determine severity and
   impact using the Common Vulnerability Scoring System (CVSS).
3. If valid, Red Hat assigns a **CVE ID** (Red Hat is a CVE Numbering Authority).

### Remediation and Patching

1. Embargoed fixes are developed in **private branches** or forks to prevent
   premature disclosure.
2. Security patches undergo **peer review** by at least one other maintainer
   with relevant domain knowledge.
3. Patches are tested against the reproduction steps from the original report
   and validated against regression test suites via OCP's CI
   infrastructure.
4. Fixes are distributed in the following OKD release.

### Coordinated Vulnerability Disclosure (CVD)

OKD follows [Red Hat's Coordinated Vulnerability Disclosure](https://access.redhat.com/articles/red-hat-coordinated-vulnerability-disclosure)
model:

1. **Embargo Period**: Vulnerability details remain confidential until a fix is
   available and released. Confidential and embargoed reports are treated as
   TLP:RED until a mutually agreed-upon public date is reached.
2. **Coordination**: Red Hat coordinates with the vulnerability reporter,
   relevant upstream communities, and partners during the embargo.
3. **Public Disclosure**: Occurs simultaneously with or immediately after the
   availability of a patched release. Red Hat publishes a security advisory to
   inform users.
4. **Attribution**: Red Hat attributes findings to the researcher by default.
   Requests for confidentiality are respected.

## Secure Development Practices

OKD uses OCP codebase, which follows established industry practices for secure development, including
but not limited to:

- **Mandatory peer review**: All code changes require review and approval via
  the [OWNERS file](https://git.k8s.io/community/contributors/guide/owners.md)
  model enforced by Prow. PRs cannot merge without at least one `/lgtm` from a
  reviewer and one `/approve` from a listed approver.
- **CI-gated merges**: All pull requests must pass presubmit test jobs in
  [Prow](https://docs.prow.k8s.io/) before merging. CI job configuration is
  centralized in the
  [openshift/release](https://github.com/openshift/release) repository.
- **Immutable release payloads**: Each OKD release is a container image
  containing a manifest of pinned image digests (SHA256), not mutable tags.
  The Cluster Version Operator (CVO) orchestrates upgrades exclusively from
  payload contents.
- **Image-based OS**: OKD runs on CentOS Stream CoreOS,
  an immutable, image-based operating system. OKD does not use
  RPM repositories at runtime, reducing the supply chain attack surface.
- **Vendored dependencies**: Go modules with vendored dependencies provide
  reproducible builds. Changes to `go.mod`, `go.sum`, or `vendor/` directories
  are automatically labeled for dedicated review scrutiny.

## Handling Incidents for Underlying Infrastructure and Tooling

OKD's build, test, and release infrastructure includes several components, each
with its own incident handling process:

| Component                      | Owner                                                                                                | Incident Channel                      |
| ------------------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------- |
| Prow CI                        | OpenShift Test Platform team via [openshift/release](https://github.com/openshift/release)           | Red Hat standard advisory channels    |
| Tekton release pipelines       | OKD team via [okd-project/okd-release-pipeline](https://github.com/okd-project/okd-release-pipeline) | OKD Security Email                    |
| Container registries (quay.io) | Red Hat Quay operations                                                                              | Red Hat standard advisory channels    |
| Upstream Prow                  | Kubernetes [test-infra](https://github.com/kubernetes/test-infra) project                            | Upstream Kubernetes security process  |
| CentOS Stream CoreOS           | CentOS Stream communities and Red Hat                                                                | Respective project security processes |

## Supported Versions and End-of-Life

OKD is a community distribution of Kubernetes and does not carry formal support
SLAs equivalent to Red Hat OpenShift Container Platform.

### Release Cadence

New stable releases are promoted approximately every two weeks from tested
nightly builds. Release status is tracked at
<https://origin-release.ci.openshift.org/>.

### Version Support

OKD is designed to move fast and drop versions quickly. At any given point there
are two active releases: the current **stable** release and the **next** release
in development. Once a new minor version (e.g., 4.22) is promoted to the
`4-stable` channel, prior minor versions (e.g., 4.21) no longer receive updates
through that channel. Security fixes are applied to the **current stable
release**; backports to older minor versions are provided on a **best-effort,
community-driven basis** and are not guaranteed.

## EU Cyber Resilience Act — Open Source Steward Statement

This project is stewarded by **Red Hat, Inc.**, an open source software steward
as defined in Article 3(14) of the
[EU Cyber Resilience Act (Regulation 2024/2847)](https://eur-lex.europa.eu/eli/reg/2024/2847/oj/eng).

- **Steward contact**: <cra-steward@redhat.com>

Refer to [Red Hat's CRA Stewardship Guidelines](https://access.redhat.com/security/eu-cyber-resilience-act-stewardship-guidelines)
and [Red Hat's security practices and vulnerability management policy](https://access.redhat.com/security/)
for detailed information.
