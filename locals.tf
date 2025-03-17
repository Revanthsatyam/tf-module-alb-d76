locals {
  name = var.internal ? "private" : "public"
  tags = merge(var.tags, { Name = "tf-module-alb" }, { env = var.env })
}