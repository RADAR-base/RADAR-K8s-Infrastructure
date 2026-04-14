locals {

  eks_core_versions = {
    "1.35" : {
      "cluster_version" = "1.35"
      "cluster_addons" = {
        "coredns"        = "v1.13.2-eksbuild.3"
        "kube_proxy"     = "v1.35.0-eksbuild.2"
        "vpc_cni"        = "v1.21.1-eksbuild.1"
        "ebs_csi_driver" = "v1.56.0-eksbuild.1"
      }
    },
    "1.34" : {
      "cluster_version" = "1.34"
      "cluster_addons" = {
        "coredns"        = "v1.12.3-eksbuild.1"
        "kube_proxy"     = "v1.34.0-eksbuild.2"
        "vpc_cni"        = "v1.20.4-eksbuild.2"
        "ebs_csi_driver" = "v1.56.0-eksbuild.1"
      }
    },
    "1.33" : {
      "cluster_version" = "1.33"
      "cluster_addons" = {
        "coredns"        = "v1.12.1-eksbuild.2"
        "kube_proxy"     = "v1.33.3-eksbuild.4"
        "vpc_cni"        = "v1.20.4-eksbuild.2"
        "ebs_csi_driver" = "v1.56.0-eksbuild.1"
      }
    },
    "1.32" : {
      "cluster_version" = "1.32"
      "cluster_addons" = {
        "coredns"        = "v1.11.4-eksbuild.14"
        "kube_proxy"     = "v1.32.0-eksbuild.2"
        "vpc_cni"        = "v1.19.2-eksbuild.1"
        "ebs_csi_driver" = "v1.37.0-eksbuild.2"
      }
    },
  }

  storage_classes = {
    gp2 = "radar-base-ebs-sc-gp2"
    gp3 = "radar-base-ebs-sc-gp3"
    io1 = "radar-base-ebs-sc-io1"
    io2 = "radar-base-ebs-sc-io2"
  }

}
