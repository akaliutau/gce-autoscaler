# Terraform Google Container VM Metadata Module

This module handles the generation of metadata for [deploying containers on GCE instances](https://cloud.google.com/compute/docs/containers/deploying-containers).

This module itself does not launch an instance or managed instance group, generates metadata instead.

## Usage

```hcl
module "gce-container" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm"
  version = "0.1.0"

  container = {
    image="gcr.io/google-samples/hello-app:1.0"
    env = [
      {
        name = "TEST_VAR"
        value = "Hello World!"
      }
    ],

    # Declare volumes to be mounted.
    # This is similar to how docker volumes are declared.
    volumeMounts = [
      {
        mountPath = "/cache"
        name      = "tempfs-0"
        readOnly  = false
      },
      {
        mountPath = "/persistent-data"
        name      = "data-disk-0"
        readOnly  = false
      },
    ]
  }

  # Declare the Volumes which will be used for mounting.
  volumes = [
    {
      name = "tempfs-0"

      emptyDir = {
        medium = "Memory"
      }
    },
    {
      name = "data-disk-0"

      gcePersistentDisk = {
        pdName = "data-disk-0"
        fsType = "ext4"
      }
    },
  ]

  restart_policy = "Always"
}
```

