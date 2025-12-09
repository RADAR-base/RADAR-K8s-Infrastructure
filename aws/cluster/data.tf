locals {

  eks_core_versions = {
    "1.32" : {
      "cluster_version" = "1.32"
      "cluster_addons" = {
        "coredns"        = "v1.11.4-eksbuild.14"
        "kube_proxy"     = "v1.32.0-eksbuild.2"
        "vpc_cni"        = "v1.19.2-eksbuild.1"
        "ebs_csi_driver" = "v1.37.0-eksbuild.2"
      }
    },
    "1.31" : {
      "cluster_version" = "1.31"
      "cluster_addons" = {
        "coredns"        = "v1.11.3-eksbuild.2"
        "kube_proxy"     = "v1.31.2-eksbuild.3"
        "vpc_cni"        = "v1.19.0-eksbuild.1"
        "ebs_csi_driver" = "v1.37.0-eksbuild.1"
      }
    },
    "1.30" : {
      "cluster_version" = "1.30"
      "cluster_addons" = {
        "coredns"        = "v1.11.3-eksbuild.2"
        "kube_proxy"     = "v1.30.6-eksbuild.3"
        "vpc_cni"        = "v1.19.0-eksbuild.1"
        "ebs_csi_driver" = "v1.37.0-eksbuild.1"
      }
    },
    "1.29" : {
      "cluster_version" = "1.29"
      "cluster_addons" = {
        "coredns"        = "v1.11.3-eksbuild.2"
        "kube_proxy"     = "v1.29.10-eksbuild.3"
        "vpc_cni"        = "v1.19.0-eksbuild.1"
        "ebs_csi_driver" = "v1.37.0-eksbuild.1"
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
