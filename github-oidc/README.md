# GitHub Actions OIDC role

Lets the **Deploy** workflow in `.github/workflows/deploy.yml` sign in to AWS **without any stored access keys**.

GitHub gives every workflow run a short-lived signed token. AWS checks that the token comes from this repository and branch, and hands back temporary credentials for one IAM role.

## Why it is a separate stack

`../terraform` is destroyed after every test to save money. This stack holds only free IAM resources, so it stays in place and the role is still there the next time the ECS stack is applied.

## What it creates

| Resource | Purpose |
|---|---|
| `aws_iam_openid_connect_provider.github` | Tells AWS to trust tokens from `token.actions.githubusercontent.com` (one per account) |
| `aws_iam_role.deploy` | Role the workflow assumes. Trust policy requires `aud = sts.amazonaws.com` and `sub = repo:<owner>/<repo>:ref:refs/heads/<branch>` |
| `aws_iam_role_policy.deploy` | Push to one ECR repository, register task definitions, update one ECS service, and pass the two task roles to ECS |

Pull requests and other branches get a different `sub`, so they cannot assume the role.

## Use it

```bash
cd github-oidc
terraform init
terraform plan
terraform apply
terraform output -raw role_arn
```

Then add the role ARN to the GitHub repository: **Settings, Secrets and variables, Actions, New repository secret**, name `AWS_ROLE_ARN`.

If the apply fails with `EntityAlreadyExists` for the OIDC provider, the account already has one. Run again with `-var create_oidc_provider=false`.

## Troubleshooting

| Error in the workflow | Cause |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | The `sub` does not match. Check the owner, repository and branch variables. A job that uses a GitHub Environment has a different `sub`. |
| `Credentials could not be loaded` | The workflow is missing `permissions: id-token: write`. |
| `AccessDeniedException ... is not authorized to perform: ecs:...` | The error names the missing action. Add it to `aws_iam_role_policy.deploy` and apply again. |
