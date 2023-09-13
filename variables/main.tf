resource "local_file" "foo" {
    content = var.content
    filename = "./file.txt"
}

variable "content" {
    default = "file content string example"
    type = string
    description = "Content of file.txt"
}