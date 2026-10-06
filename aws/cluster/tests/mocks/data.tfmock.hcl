mock_resource "aws_eks_cluster" {
  defaults = {
    arn      = "arn:aws:eks:eu-west-2:123456789012:cluster/radar-base-test"
    endpoint = "https://radar-base-test.eks.eu-west-2.amazonaws.com"
    # Throwaway self-signed certificate.
    certificate_authority = [{ data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQWUrZ0F3SUJBZ0lVYVhlNjhQb0RYUndpaFdyYnNBczZ4T3cwUStRd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0VqRVFNQTRHQTFVRUF3d0hkR1Z6ZEMxallUQWdGdzB5TmpFd01EUXhNak01TkRSYUdBOHlNVEkyTURreApNREV5TXprME5Gb3dFakVRTUE0R0ExVUVBd3dIZEdWemRDMWpZVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFECmdnRVBBRENDQVFvQ2dnRUJBSzdqM3VsQ1hhaTc1VXArdVFia1U1dmN1TEJneW1RQmQ5TGlqd0d5anY1cHNGT1gKU2R6YlZScWJjbGlnUkdOVzBBYU9uSi9NRTFUR3Jkc3RXWkdUa2JyU0Q3aUZsZGlKaGNyUDREZUJPVEdDRnFReApRZ2o4YU1pUC93Mk5iR1kwNGF0OXNiMUdkNTZjSDRvTGdwM0kwWVl5K2JxUUVFLzFyOGhsYldHTG82bHRJRTNiCkNscGZmME50ZU4xVzh0QmxyRHpCUGkvU2Z0cGlOeW9OWFoybFMrMkJTUlJpK2xjeVlSelJpcmUvakg5MnFQLzAKU0hra0FiK2RXMGFrWnhFc2lienhiNnNybGhvb3F5d2ZHMEQ1Ylc2bzIwUkI1SnhTOGl3TzN2Q1luQzNqaU5uTwp0cEloZ0pZQ1VyN3RRN1M1ajFScXVxNEVGM3BnM0hCdXNEQ0YrWUVDQXdFQUFhTlRNRkV3SFFZRFZSME9CQllFCkZQV1FzZjJjODJSRlMzK1RoY0RqcWF0WW51UU9NQjhHQTFVZEl3UVlNQmFBRlBXUXNmMmM4MlJGUzMrVGhjRGoKcWF0WW51UU9NQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQVhnL0lLYQpuanZiZkR5UVVaeDlWcjlJOWs0UjZaSC9DOVIySi8xT3lxY1Z3NWhVaWtBK0FGZGRaUnZscWpNYTdvbG14bGtICjdubW04UmRuT3o3bFJLeGQ1VDhObkJuR3RxSGVwSXZlK29oTWlhRGR6SmJnQlh0OXBiWkYvZFRKcUpxMkNuNFcKTkxjTXZkYllHbnAxTEVXSm9tS01HREhRdGhnTGdoM2pBUm1TV1UrRndPNElJSEltNkRkc1NRRURVbEk5Wk9mVQo0VEd6Snd0YnZZbTFhTVU0QmpQRFJNU0w3TWRxbEpYaUJNbTl1NWdtbC94ZEZFdDRGYXFXandJOEdraENVb2t2CkNtbWpMRUh3RjcxdjFLMmQ4VjVXWEI2T0t3OEZWOXRPN0VlUlNuenYwMjN5UzJmVW02RGYrMXV5MUhzOWFhTE4KQ0hpM0JJamt1NWh5OXpzPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==" }]
    identity = [{
      oidc = [{
        issuer = "https://oidc.eks.eu-west-2.amazonaws.com/id/0123456789ABCDEF"
      }]
    }]
  }
}

mock_resource "aws_eks_node_group" {
  defaults = {
    id            = "arn:aws:eks:eu-west-2:123456789012:nodegroup/radar-base-test/default"
    node_group_id = "arn:aws:eks:eu-west-2:123456789012:nodegroup/radar-base-test/default"
    status        = "ACTIVE"
  }
}

mock_data "aws_availability_zones" {
  defaults = {
    names    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    zone_ids = ["euw2-az1", "euw2-az2", "euw2-az3"]
  }
}

mock_data "aws_caller_identity" {
  defaults = {
    account_id = "123456789012"
    arn        = "arn:aws:iam::123456789012:root"
    user_id    = "AIDAEXAMPLEUSERID"
  }
}

mock_data "aws_region" {
  defaults = {
    name        = "eu-west-2"
    description = "Europe (London)"
  }
}

mock_data "aws_partition" {
  defaults = {
    partition  = "aws"
    dns_suffix = "amazonaws.com"
  }
}

mock_data "aws_iam_policy_document" {
  defaults = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"TestAssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  }
}
