variable "instences" {
  type = map(object({
    vm_size    = string
    disk       = string
    IP_address = string
    user_name  = string
  }))
  default = {
    0 = {
      vm_size    = "Standard_DS1_v2"
      disk       = "128"
      IP_address = "10.172.4.5"
      user_name  = "user1"
    }
    1 = {
      vm_size    = "Standard_DS1_v2"
      disk       = "128"
      IP_address = "10.172.4.6"
      user_name  = "user2"
    }
  }
}
variable "willget" {
  type      = string
  sensitive = true
  default   = "Password@123"
}
 