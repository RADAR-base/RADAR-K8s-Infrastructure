locals {

  eks_core_versions = {
    "1.27" : {
      "cluster_version" = "1.27"
      "cluster_addons" = {
        "coredns"        = "v1.10.1-eksbuild.7"
        "kube_proxy"     = "v1.27.10-eksbuild.2"
        "vpc_cni"        = "v1.15.3-eksbuild.1"
        "ebs_csi_driver" = "v1.25.0-eksbuild.1"
      }
    },
    "1.26" : {
      "cluster_version" = "1.26"
      "cluster_addons" = {
        "coredns"        = "v1.9.3-eksbuild.2"
        "kube_proxy"     = "v1.26.2-eksbuild.1"
        "vpc_cni"        = "v1.12.2-eksbuild.1"
        "ebs_csi_driver" = "v1.17.0-eksbuild.1"
      }
    },
    "1.25" : {
      "cluster_version" = "1.25"
      "cluster_addons" = {
        "coredns"        = "v1.9.3-eksbuild.2"
        "kube_proxy"     = "v1.25.6-eksbuild.1"
        "vpc_cni"        = "v1.12.2-eksbuild.1"
        "ebs_csi_driver" = "v1.16.0-eksbuild.1"
      }
    }
  }

  storage_classes = {
    gp2 = "radar-base-ebs-sc-gp2"
    gp3 = "radar-base-ebs-sc-gp3"
    io1 = "radar-base-ebs-sc-io1"
    io2 = "radar-base-ebs-sc-io2"
  }

}