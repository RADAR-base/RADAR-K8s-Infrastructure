AWS_REGION       = "eu-west-2"
environment      = "dev"
domain_name      = {} # Pair of top level domain and hosted zone ID for deployed applications, e.g., { "radar-base.org" : "ZABCDEFGHIJKLMNOPQRST" }
with_dmz_pods    = false
enable_metrics   = false
enable_karpenter = false
enable_msk       = false
enable_rds       = false
enable_route53   = false
enable_ses       = false
enable_s3        = false
enable_eip       = false
