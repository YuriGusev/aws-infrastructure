module "sennomaj-blog-infrastructure" {
  source              = "../modules/hugo-infrastructure"
  aliases             = ["www.sennomaj.com", "sennomaj.com"]
  domain_name         = "sennomaj.com"
  bucket_name         = "www.sennomaj.com"
  deployment_user_arn = "arn:aws:iam::602537810458:user/sennomaj-deployment-cli"
}