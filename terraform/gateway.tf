resource "aws_api_gateway_rest_api" "omdb_proxy" {
  name = "OMDB_Proxy"
  description = "Terraform Serverless Application omdb_proxy"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.omdb_proxy.invoke_url}"
}
