variable "region" {
  type    = string
  #default = "us-east-1"
}

variable "access_key" {
  type    = string
  default = "enter yours"
}

variable "secret_key" {
  type    = string
  #default = "enter yours"
}
  variable "vault_addr" {
    type = string
    default = "http://127.0.0.1:8200"
  }

  variable "vault_token" {
    type = string
    #default = "enter yours"
  }