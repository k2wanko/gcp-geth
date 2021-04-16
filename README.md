# GCP Geth

### Prepare

Require:
- gcloud
- terraform

Refer to [this document](https://cloud.google.com/resource-manager/docs/creating-managing-projects) to create a project and determine the [project_id].


```bash
gcloud config set project [project_id]
gcloud auth application-default login
gcloud services enable compute.googleapis.com
```

### Create Instance

```
terraform apply
```

### geth attach

```
gcloud compute ssh [instance_name] -- -N -L 8545:localhost:8545
geth attach rpc:http://localhost:8545
```