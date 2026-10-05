mock_data "aws_eks_cluster" {
  defaults = {
    id       = "radar-base-test"
    arn      = "arn:aws:eks:eu-west-2:123456789012:cluster/radar-base-test"
    endpoint = "https://radar-base-test.eks.eu-west-2.amazonaws.com"
    # Throwaway self-signed certificate
    certificate_authority = [{ data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQWUrZ0F3SUJBZ0lVYVhlNjhQb0RYUndpaFdyYnNBczZ4T3cwUStRd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0VqRVFNQTRHQTFVRUF3d0hkR1Z6ZEMxallUQWdGdzB5TmpFd01EUXhNak01TkRSYUdBOHlNVEkyTURreApNREV5TXprME5Gb3dFakVRTUE0R0ExVUVBd3dIZEdWemRDMWpZVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFECmdnRVBBRENDQVFvQ2dnRUJBSzdqM3VsQ1hhaTc1VXArdVFia1U1dmN1TEJneW1RQmQ5TGlqd0d5anY1cHNGT1gKU2R6YlZScWJjbGlnUkdOVzBBYU9uSi9NRTFUR3Jkc3RXWkdUa2JyU0Q3aUZsZGlKaGNyUDREZUJPVEdDRnFReApRZ2o4YU1pUC93Mk5iR1kwNGF0OXNiMUdkNTZjSDRvTGdwM0kwWVl5K2JxUUVFLzFyOGhsYldHTG82bHRJRTNiCkNscGZmME50ZU4xVzh0QmxyRHpCUGkvU2Z0cGlOeW9OWFoybFMrMkJTUlJpK2xjeVlSelJpcmUvakg5MnFQLzAKU0hra0FiK2RXMGFrWnhFc2lienhiNnNybGhvb3F5d2ZHMEQ1Ylc2bzIwUkI1SnhTOGl3TzN2Q1luQzNqaU5uTwp0cEloZ0pZQ1VyN3RRN1M1ajFScXVxNEVGM3BnM0hCdXNEQ0YrWUVDQXdFQUFhTlRNRkV3SFFZRFZSME9CQllFCkZQV1FzZjJjODJSRlMzK1RoY0RqcWF0WW51UU9NQjhHQTFVZEl3UVlNQmFBRlBXUXNmMmM4MlJGUzMrVGhjRGoKcWF0WW51UU9NQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQVhnL0lLYQpuanZiZkR5UVVaeDlWcjlJOWs0UjZaSC9DOVIySi8xT3lxY1Z3NWhVaWtBK0FGZGRaUnZscWpNYTdvbG14bGtICjdubW04UmRuT3o3bFJLeGQ1VDhObkJuR3RxSGVwSXZlK29oTWlhRGR6SmJnQlh0OXBiWkYvZFRKcUpxMkNuNFcKTkxjTXZkYllHbnAxTEVXSm9tS01HREhRdGhnTGdoM2pBUm1TV1UrRndPNElJSEltNkRkc1NRRURVbEk5Wk9mVQo0VEd6Snd0YnZZbTFhTVU0QmpQRFJNU0w3TWRxbEpYaUJNbTl1NWdtbC94ZEZFdDRGYXFXandJOEdraENVb2t2CkNtbWpMRUh3RjcxdjFLMmQ4VjVXWEI2T0t3OEZWOXRPN0VlUlNuenYwMjN5UzJmVW02RGYrMXV5MUhzOWFhTE4KQ0hpM0JJamt1NWh5OXpzPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==" }]
    identity = [{
      oidc = [{
        issuer = "https://oidc.eks.eu-west-2.amazonaws.com/id/0123456789ABCDEF"
      }]
    }]
  }
}

mock_data "aws_eks_cluster_auth" {
  defaults = {
    token = "test-eks-token"
  }
}

mock_data "aws_eks_node_groups" {
  defaults = {
    names = ["worker-radar-base-test-20260410000000"]
  }
}

mock_data "aws_eks_node_group" {
  defaults = {
    id            = "arn:aws:eks:eu-west-2:123456789012:nodegroup/radar-base-test/default"
    arn           = "arn:aws:eks:eu-west-2:123456789012:nodegroup/radar-base-test/default"
    status        = "ACTIVE"
    node_role_arn = "arn:aws:iam::123456789012:role/radar-base-test-worker-node-group"
    subnet_ids    = ["subnet-private-a"]
  }
}

mock_data "aws_subnets" {
  defaults = {
    ids = ["subnet-private-a", "subnet-private-b", "subnet-private-c"]
  }
}

mock_data "aws_subnet" {
  defaults = {
    cidr_block        = "10.0.0.0/19"
    availability_zone = "eu-west-2a"
    state             = "available"
  }
}

mock_data "aws_vpc" {
  defaults = {
    id                   = "vpc-0123456789abcdef0"
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    owner_id             = "123456789012"
  }
}

mock_data "aws_security_group" {
  defaults = {
    id   = "sg-0123456789abcdef0"
    name = "radar-base-test-node"
  }
}

mock_data "aws_route53_zone" {
  defaults = {
    zone_id = "Z0123456789ABCDEFGHIJ"
    name    = "radar-base.test"
  }
}

mock_data "aws_availability_zones" {
  defaults = {
    names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  }
}

mock_resource "aws_ses_domain_dkim" {
  defaults = {
    dkim_tokens = ["token1", "token2", "token3"]
  }
}

mock_data "aws_iam_policy_document" {
  defaults = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"TestAssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  }
}
