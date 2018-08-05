# terraform 1.0.0
Deploying [golang-http](https://github.com/sebosp/golang-http) simple app using:
- terraform v0.11.7
- AWS remote state
- GKE Kubernetes 1.10.5
- Terraform provided Kubernetes Namespaces and ConfigMaps
- Jenkins-X-powered golang-http pipelines.

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
alias PROD='docker run --rm --cap-add=SYS_PTRACE -v $HOME/:/home/sre/work/ -e TARGET_ENV=PROD -e LOCAL_USER_ID=`id -u $USER` -it sebosp/tvl:2.0.1'
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

