resource "aws_key_pair" "deployer" {
  key_name   = "deploy"
  public_key = file("./keys/developer_rsa.pub")
}
