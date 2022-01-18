# About

This is a research project to study autoscaling on GCE


# Implementation

This is a simple Spring Boot - based project to build a cluster of scalable apps to process messages from PubSub topic. 

## Further details

There is a topic - `incoming_files` -  to publish messages to, and a cluster of processors (processor app) subscribed to this topic. 
These applications can pickup messages from the topic and process them.

Each message has the following format:

```
{
  "id": "<unique uuid>"
}
```

- Field `id` is required and must be unique across all letters

After picking up message the Processor app publish event about this into the 2nd topic `processed_files`, adding several more fields:

```
{
  "id": "<unique uuid>",
  "processor_id": "<unique among all instances>",
  "billed_time_ms": "processing time in ms"
}
```


# How to build

Here the sequence of steps to perform (most of these steps will be covered in next sections)

* Create Docker images for `processor` app
* Upload the Docker images to a private Docker registry at Google using `docker push` command
* Use Terraform to define infrastructure-as-a-code which includes a Google Cloud k8s instances and PubSub topics/subscriptions.
* Deploy a infrastructure using Terraform to Google Cloud


gcloud compute --project "message-multi-processor" instance-groups managed recreate-instances  "processors-1" --zone "europe-west2-c" --instances "processors-1-bjd9"


# Requirements

* gcloud (see [2])
* Java 11 SDK
* terraform (see [4])
* ssh


# Environment settings

The Spring Cloud GCP Core Boot starter can be auto-configured using properties from the properties file (`src/main/resources/application.yaml`) 
which always have precedence over the Spring Boot configuration.

The GCP project ID is auto-configured from the `GOOGLE_CLOUD_PROJECT` environment variable, among several other sources. 

The OAuth2 credentials are auto-configured from the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

This var can be set manually after auto-generating json with google account credentials:

```
gcloud auth application-default login
```


The path to gcloud creds usually has the form:

```
/$HOME/.config/gcloud/legacy_credentials/$EMAIL/adc.json
```

where variable $EMAIL can be obtained via command:

```
gcloud config list account --format "value(core.account)"
```

Add GOOGLE_APPLICATION_CREDENTIALS as permanent vars into the file:

```
sudo -H gedit /etc/environment
```

To access cloud instances the SSH key is needed, it can be created using the following command:

```
ssh-keygen -t rsa -f ~/.ssh/pubsub_rsa -C $USERNAME -b 2048
```

# Settings on GCP side

(0) For convenience and generalization, set the env variable GOOGLE_CLOUD_PROJECT in file set_env.sh to your project id, f.e. 
`export GOOGLE_CLOUD_PROJECT=message-multi-processor`

(1) Create a project:

```
gcloud projects create $GOOGLE_CLOUD_PROJECT
```

After successful creation project_id must be visible via command `gcloud projects list`

(2) Activate billing account for project and enable PubSub and GKE services

(3) Build an image with app and push it to GCloud private docker registry, f.e. :

```
sudo docker build -t processor:0.0.1 ./processor/
```

Docker image can be tested with the help of command (`ctrl+shift+c` to stop):
```
sudo docker run -p 8080:8080 \
    --env=GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT \
    --env=GOOGLE_APPLICATION_CREDENTIALS=/secrets/adc.json \
    --volume=$GOOGLE_APPLICATION_CREDENTIALS:/secrets/adc.json \
    processor:0.0.1
```

(4) Authenticate the docker registry (after update, the following will be written to your Docker config file located at  
`/root/.docker/config.json`), and push the image:

```
curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" > helper.tar.gz
tar xz -f ./helper.tar.gz
sudo mv ./docker-credential-gcr  /usr/local/bin/docker-credential-gcr
sudo chmod +x /usr/local/bin/docker-credential-gcr
sudo docker-credential-gcr configure-docker
```

then tag the image and push it to the registry:

```
sudo docker tag processor:0.0.1 gcr.io/$GOOGLE_CLOUD_PROJECT/processor:v1
sudo docker push gcr.io/$GOOGLE_CLOUD_PROJECT/processor:v1
```

(5) Verify the pulling docker image from GCP registry: test the image with the following command, 
which will run a Docker container as a daemon on port 9000 from your newly created container image:

```
sudo docker run -ti --rm -p 8080:8080 \
  --env=GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT \
  --env=GOOGLE_APPLICATION_CREDENTIALS=/secrets/adc.json \
  --volume=$GOOGLE_APPLICATION_CREDENTIALS:/secrets/adc.json \
  gcr.io/$GOOGLE_CLOUD_PROJECT/processor:v1
```

(6) Create infrastructure using Terraform:

For Terraform it's necessary to set in file set_env.sh the following variables:

```
export TF_VAR_google_app_creds=$GOOGLE_APPLICATION_CREDENTIALS
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT
```
(8) Run terraform init to download the latest version of the provider and build the .terraform directory

```
terraform init
terraform plan
terraform apply
```

Instances will be available via command:

```
gcloud compute instances list
```

One can login to them and inspect using SSH access and then see the startup logs, check the java version, etc:

```
gcloud beta compute ssh --zone "us-west1-a" "proc-vm-d1c76370a95aa91c"  --project $GOOGLE_CLOUD_PROJECT
cat /var/log/syslog 
java --version
```
Note, instance ID (here it's `proc-vm-d1c76370a95aa91c`) may change after each recreation.

## Clean up

(1) First, destroy the resources created by Terraform: 

```
terraform apply -destroy
```

 
# Testing 

Generate 50 messages using script:

```
scripts/message_generator.sh 50
```
Observe autoscaling of cluster in action using


# References

[1] https://github.com/spring-guides/gs-messaging-gcp-pubsub

[2] https://cloud.google.com/appengine/docs/flexible/java/how-instances-are-managed

[3] https://stackoverflow.com/questions/44130165/cloud-api-access-scopes


# Appendix 1. Terraform installation on Ubuntu 20.04 LTS

```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

Check the valid installation:

```
terraform -help
```

# Appendix 2. Terraform basics

*Providers*: a provider is responsible for understanding API interactions and exposing resources. 
Providers generally are an IaaS (e.g. AWS, GCP, Microsoft Azure, OpenStack), PaaS (e.g. Heroku), or SaaS services

*Resources*: resources are the most important element in the Terraform language. 
Each resource block describes one or more infrastructure objects, such as virtual networks, compute instances

*Variables*: a variable can have a default value. In case of omitted default values, Terraform will ask to provide it 
when running a terraform command

*Modules*: a module is just a folder which combines related terraform files

*Outputs*: sometimes a variable is needed which is only known after terraform has done a change on a cloud provider — 
f.e. ip-addresses that are given to application. So output serves as an intermediate holding agent - 
it takes that value and exposes it to your variables

Terraform automatically resolves dependencies, but sometimes cannot determine the order due to complex or circular dependencies.
In this case successful deployment can be achieved by applying command `terraform apply` twice 

# Appendix 3. Docker commands

The list of all available images can be accessed using `sudo docker image list` command.

Removing tagged images:

First, untag it, f.e.:

```
sudo docker image rm gcr.io/message-multi-processor/gcp-pubsub:v1
sudo docker image rm gcr.io/message-multi-processor/gcp-pubsub:latest
```

# Appendix 4. Troubleshooting

(1) This command can turn on services:

```
gcloud services enable <service>
f.e.
gcloud services enable container
```

