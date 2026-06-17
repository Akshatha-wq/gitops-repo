# Create dedicated, isolated networking resources

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0"

    name = "gitops-vpc"
    cidr = "10.0.0.0/16"

    azs = ["us-east-2a", "us-east-2b"]
    public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
}

# Build the managed EKS Control plane and worker node pool

module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~>20.0"

    cluster_name = "gitops-eks-cluster"
    cluster_version = "1.32"

    cluster_endpoint_public_access = true

    vpc_id = module.vpc.vpc_id
    control_plane_subnet_ids = module.vpc.public_subnets
    subnet_ids = module.vpc.private_subnets

    eks_managed_node_groups = {
        primary = {
            min_size = 1
            max_size = 3
            desired_size = 2

            instance_types = ["t3.medium"]
        }
    }

    enable_cluster_creator_admin_permissions = true
}

# Declaratively install ArgoCD using the Helm release resource

resource "helm_release" "argocd" {
    name = "argocd"
    repository = "https://argoproj.github.io/argo-helm"
    chart = "argo-cd"
    version          = "7.6.10"
    namespace        = "argocd"
    create_namespace = true

    set {
        name = "server.service.type"
        value = "LoadBalancer"
    }
    depends_on = [module.eks]
}

# Create an ECR repository for our application images

resource "aws_ecr_repository" "app_repo" {
    name = "my-app"
    image_tag_mutability = "MUTABLE"
    force_delete = true
}
