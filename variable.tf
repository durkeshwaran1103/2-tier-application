variable "region" {
  default = "us-east-1"
}
variable "cidr_block" {
  default = "10.0.0.0/16"
}
variable "ami" {
  default = "ami-00a929b66ed6e0de6"
}

variable "instance_type" {
    default = "t2.micro"
  
}
variable "identifier" {
    default = "database"
  
}
variable "engine" {
  default = "mysql"
}
variable "engine_version" {
    default = "8.0.32"
  
}
variable "instance_class" {
  default = "db.r5.large"

}
variable "storage_type" {
    default = "gp2"
  
}
variable "allocated_storage" {
    default = "5"
  
}
variable "username" {
    default = "admin"
  
}
variable "password" {
    default = "Durkesh@1103"
  
}
variable "vpc_security_group_ids" {
    default = ["sg-07e4050528dcf3aba"]
  
}