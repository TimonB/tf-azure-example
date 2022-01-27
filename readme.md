TF-AZURE-EXAMPLE
===

Example to create some resources in Microsoft Azure with Terraform and GitHub Actions.


# Links


- [Using Azure Storage for tfstate](https://thomasthornton.cloud/2021/03/19/deploy-terraform-using-github-actions-into-azure/)
- [Terraform Kubernetes Example](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/kubernetes)


# Hints

Upload of an existing tfstate-file can be done with a SAS-Token (as described here https://docs.microsoft.com/de-de/azure/storage/common/storage-use-azcopy-v10?toc=/azure/storage/blobs/toc.json):

```
azcopy copy terraformgithubexample.tfstate  "https://opstf.blob.core.windows.net/terraformgithubexample?sp=racw&st=2022-01-21T09:54:57Z&se=2022-01-21T17:54:57Z&spr=https&sv=2020-08-04&sr=c&sig=OmMptmjtFw5%2B49eR3W01SeAowZrg%2FksaezTJBpqkBGk%3D"
```
