variable "project" {
  default = "model-arcadia-478207-j1"
}

variable "region" {
  default = "europe-west6"
}

variable "zone" {
  default = "europe-west6-a"
}

variable "instance-name" {
  default = "loadgenerator-vm"
}

variable "deployKeyName" {
  default = "deployment_key.json"
}

variable "machineCount" {
  default = 2
}

variable "machineType" {
  default = "f1-micro"
}