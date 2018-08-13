# terraform 1.0.0
Requirements
- terraform v0.11.7
- AWS account
- jsonnet v0.11
- ruby to transform yaml to json
- Optionally GKE for kubernetes.

## Jsonnet
### Per-environment structure
The repo is built to support multiple environments:

- `vars/envs/all`: meta-environment, contains resources that can be referenced by actual envs.
- `vars/envs/dev`: A dev environment.
- `vars/envs/prod`: A prod environment.
the meta-environment `all` is an effort to re-use resources across multiple environments.

Inside each environment-specific directory, resources are further split in per-service directories,

### Example YAML resources
A group and its policies can be defined in either `all/` or `<env>/` as its considered convenient.
This structure helps map policies to groups in a very intuitive manner:
- `vars/envs/all/iam/groups.yml`
  ```yaml
  iam_groups:
    global_only_group:
      name: global_only_group
      inline_policies: ['global_policy1','global_policy2']
  ```
- `vars/envs/all/iam/policies.yml`
  ```yaml
  iam_inline_policies:
    global_policy1: |
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "GlobalPolicy1",
                  "Effect": "Allow",
                  "Action": [
                      "ec2:DescribeImages",
                      "ec2:DescribeInstances",
                      "ec2:DescribeTags"
                  ],
                  "Resource": [
                      "*"
                  ]
              }
          ]
      }
  ```
- `vars/envs/prod/iam/groups.yml`
  ```yaml
  custom_iam_groups:
    prod_only_group:
      name: prod_only_group
      inline_policies: ['global_policy1']
  ```
- `vars/envs/prod/iam/policies.yml`
  ```yaml
  custom_iam_policies: {}
  ```

As is expected, the resources defined in `all` are overwritten by resources defined in per `env` setup as long as they match their name.
Resources in `prod` can target resources in `all` but not vice-versa.

### Transforming to JSON
Jsonnet needs to parse JSON and this structure needs to be translated from YAML.
The `Makefile` target `jsonify` uses ruby but can be transformed by any other utils of your choice.
It creates a temporary directory "vars_json" that mirrors the above structure but translated YAMLs to JSON.
```bash
make jsonify
rm -rf ./vars_json && ./jsonify.sh vars ./vars_json
Creating target directory ./vars_json
Jsonifying to ./vars_json/envs/prod/iam/groups.json
Jsonifying to ./vars_json/envs/prod/iam/policies.json
Jsonifying to ./vars_json/envs/all/iam/groups.json
Jsonifying to ./vars_json/envs/all/iam/policies.json
```

After it has been transformed, jsonnet can then import these resources.

### Transforming to terraform resources
These .json files are imported by `lib/iam_group.libsonnet`
It mixes global vs custom resources and generates these terraform resources for each environment:
- aws_iam_group
- aws_iam_policy
- aws_iam_group_policy_attachment

The resulting file for this example is `vars/envs/prod/iam/groups.tf` that can be applied by `terraform apply`

## Provider: AWS
Provider AWS is used for Remote State.

### Remote State
The remote state resources are created through `aws-remote-state.tf`
Initially, terraform has the config to point to local state.
The first step is to apply this file to create:
- S3 bucket
- DynamoDB table for locking.

After these resources exist, they are referenced in `main.tf`:
```terraform
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tf-state.sebosp.com"
    key            = "tf-state"
    dynamodb_table = "tf-state-sebosp"
  }
}
```

After this change, terraform init is required.
This resource cannot have variable interpolation because of the early stage
at which it is used. That means that bucket prefix can't be used and a bucket
name must be acquired beforehand.

Once terraform init is ran, the terraform state will recide in S3.
When a terraform apply is ran, the dynamodb lock will be engaged, allowing
teams to work concurrently.

### Tagging
A series of default tags are set on `variables.tf`

### Auth
Provided by loading environments based on the environment variable
The loading of different AWS envs is accomplished by using, in docker image:
 [sebosp/tvl](https://github.com/sebosp/tvl) the variable `TARGET_ENV`.
This variable maps to a file in `~/envs/$TARGET_ENV` in the host filesystem.
This file has this format:
```bash
$ cat ~/envs/PROD 
export AWS_ACCESS_KEY_ID=AKIAxxXXXxxXXX
export AWS_SECRET_ACCESS_KEY=IGKXXXxxXX/xxXxxxxXXX
export AWS_DEFAULT_REGION=eu-west-1
```

## Provider: Google
Provider Google is used for GKE resources.

### GKE cluster
The cluster already existed and was imported.

### Node Pools
The node pools were configured to be preemptible nodes.
2 pools exists:
- 2x 1vCPU 2 GB: Booted first to run small k8s needed pods/svcs.
- 2x 2vCPU 4 GB: Booted last to run heavier workload (also supports maven, go builds, etc).

The node pools are scaled up/down by using the following scripts:
- Turn on: [linuxtweaks/gcloud-k8s-up.sh](https://github.com/sebosp/linuxtweaks/blob/develop/gcloud-k8s-up.sh)
- Turn off: [linuxtweaks/gcloud-k8s-down.sh](https://github.com/sebosp/linuxtweaks/blob/develop/gcloud-k8s-down.sh)

### Auth
Similar to the AWS Auth, a file exists in the host dir called `~/envs/GKE-${TARGET_ENV}.json`

## Provider Kubernetes
Provider Kubernetes is used for configuring namespaces and configmaps.
Jenkins-X runs on kubernetes and powers the code pipelines.

### Namespaces
configured through `k8s-ns.tf`
Ensures that namespaces jx-production and jx-staging exist.

### ConfigMaps in Staging and Production
configured through `k8s-cm.tf`
For both jx-production and jx-staging, a ConfigMap called tf-cfg is provided
with different values, mirroring an operator changing these variables based on
real values.

### ConfigMaps for Dynamic(Preview) Namespaces
These are accomplished via Helm charts [golang-http](https://github.com/sebosp/golang-http/blob/master/charts/preview/templates/configmap.yaml)
A ConfigMap is created everytime a preview namespace is started.
The ConfigMaps in jx-production and jx-staging are untouched.

### Services and Deployments.
It is a gray area who should own the Services and Deployments.
While it could be owned by Terraform it would be unaware of CD latest versioning
Of course. the CI pipeline could be changed so that a variables.tf is updated
with the latest golang-http production ready version.

## Running
A docker image is provided with known-to-work versions of 
terraform/go/aws-cli/etc/etc: [sebosp/tvl](https://github.com/sebosp/tvl)
```bash
alias PROD='docker run --rm --cap-add=SYS_PTRACE -v $HOME/:/home/sre/work/ -e TARGET_ENV=PROD -e LOCAL_USER_ID=`id -u $USER` -it sebosp/tvl:2.0.3'
```

## TODO
- In general, the structure is not meant for multiple environments/workspaces.
Given the size of the project (at least initially), it has not been seen as
worth dividing into versioned modules.
- Figure out CI. Allowing terraform lint checks, ensure required tags are set,
create PRs before any `terraform apply`
- Document and automate google authentication.
- Add gcloud to tvl image.
- Test AWS EKS

