variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+FkIaSUP3ixaVIV8vdJrzQpdMYpTAT0rBhRa6mZ/lC1r/+mxhvasde5VgJ8tecRyhsP4OBBD8ZfDtm4g1pgM1AqxMgK9t7Xf5nJ7gLsa4RxkSz0vGtyNzD4QXjftuiE/GsZdQy/uybwxi9WYEG26tE7a0bCvv4/8HCb1em3dn6OUSEyNYpsB3YTjUybNn2j8kRznF8shrFI9oYu8TRQFT4WLzEnGPxlzqoYgGGKXqsvxvoXsvRj0eOw0lcLSWpS3j5rdEtQGhpq/HASBJ/0+T4Fbo0HhCfzFFVhWfA/uxKKx0ju5HHpOCys2MDuJTqnPRJVgNdliRzlCHtEnGPQJsuPCMCjIjIwgzleApF1nrvgdbUdR1R14ehcCfFIX+0BKe81Ug51ihhWgWh5dCK9U0ubA/sn9Ye2dPPt35wVkG8wgDSwk6fG72ibft774bux0a33/WYTuHdxbFgsynYC3o6Lj32Dm7xuR+bydaNXuEqFDONU0r+Cmlrdkqi8mLxo7PvlQHxZQTDvlLGdKhJJQQjXofdg4kZULIR5ZLt/ViukcjAH5S+WrgWPocHXke52jr4VUUTEY+1wkJzFYIx4yJ3HdXMRFGiaemlBQkXgCPDIgT007/D9lwBBh/kn6tYBBrx53PG77Lz/IE0oDF13DBp2RNuEEsO0Nf2wgCB1i10Q== tbirk@MacBook-Pro-von-Birk.local"
}

variable "resource_group_name" {
  description = "Name of the resource group."
  default     = "myResourceGroup"
}

variable "location" {
  description = "Location of the cluster."
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Environment"
  default     = "development"
}
