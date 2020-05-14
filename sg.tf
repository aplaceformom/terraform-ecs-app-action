resource "aws_security_group" "self" {
  description = "${var.name} self-group access"
  vpc_id      = var.network_vpc_id

  ingress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }
}
