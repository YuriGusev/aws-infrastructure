data "aws_route53_zone" "zone" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "root_domain" {
  zone_id = data.aws_route53_zone.zone.id
  name = var.domain_name
  type = "A"

  alias {
    name = aws_cloudfront_distribution.hugo[0].domain_name
    zone_id = aws_cloudfront_distribution.hugo[0].hosted_zone_id
    evaluate_target_health = false
  }
}