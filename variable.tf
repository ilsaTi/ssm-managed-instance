variable "props" {
    type = map(string)
    default = {
        region = "us-east-1"
        subnet = "subnet-ff0cb1a0"
        type = "t2.micro"
        ami = "ami-0b0af3577fe5e3532"
    }
}