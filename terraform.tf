provider "aws" {
  region = "${var.region}"
}

/*
Store infrastructure state in a remote store (instead of local machine):
https://www.terraform.io/docs/state/purpose.html
*/
terraform {
  backend "s3" {
    bucket  = "terraform-state-002"
    key     = "tvs/terraform.tfstate" # When using workspaces this changes to ':env/{terraform.workspace}/tvs/terraform.tfstate'
    region  = "eu-west-2"
    encrypt = "true"
  }
}

module "core" {
  source = "./terraform/modules/core"

  environment          = "${terraform.workspace}"
  project_name         = "${var.project_name}"
  vpc_cidr             = "${var.vpc_cidr}"
  availability_zones   = "${var.availability_zones}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  availability_zones   = "${var.availability_zones}"
  ssh_ips              = "${var.ssh_ips}"

  region                   = "${var.region}"
  load_balancer_check_path = "${var.load_balancer_check_path}"
  alb_certificate_arn      = "${var.alb_certificate_arn}"
  image_id                 = "${var.image_id}"
  instance_type            = "${var.ecs_instance_type}"
  ecs_key_pair_name        = "${var.ecs_key_pair_name}"

  asg_name         = "${var.asg_name}"
  asg_max_size     = "${var.asg_max_size}"
  asg_min_size     = "${var.asg_min_size}"
  asg_desired_size = "${var.asg_desired_size}"

  ecs_cluster_name                  = "${module.ecs.cluster_name}"
  ecs_service_name                  = "${module.ecs.service_name}"
  aws_iam_ecs_instance_profile_name = "${module.ecs.aws_iam_ecs_instance_profile_name}"
}

module "ecs" {
  source = "./terraform/modules/ecs"

  environment                                    = "${terraform.workspace}"
  project_name                                   = "${var.project_name}"
  region                                         = "${var.region}"
  ecs_cluster_name                               = "${var.ecs_cluster_name}"
  ecs_service_name                               = "${var.project_name}_${terraform.workspace}_${var.ecs_service_name}"
  ecs_service_task_name                          = "${var.project_name}_${terraform.workspace}_${var.ecs_service_task_name}"
  ecs_service_task_count                         = "${var.ecs_service_task_count}"
  ecs_service_task_port                          = "${var.ecs_service_task_port}"
  ecs_service_task_definition_file_path          = "${var.ecs_service_task_definition_file_path}"
  ecs_import_schools_task_definition_file_path   = "${var.ecs_import_schools_task_definition_file_path}"
  ecs_vacancies_scrape_task_definition_file_path = "${var.ecs_vacancies_scrape_task_definition_file_path}"
  import_schools_entrypoint                      = "${var.import_schools_entrypoint}"
  vacancies_scrape_entrypoint                    = "${var.vacancies_scrape_entrypoint}"
  vacancies_scrape_schedule_expression           = "${var.vacancies_scrape_schedule_expression}"

  aws_alb_target_group_arn      = "${module.core.alb_target_group_arn}"
  aws_cloudwatch_log_group_name = "${module.logs.aws_cloudwatch_log_group_name}"

  # Application variables
  rails_env                = "${var.rails_env}"
  default_school_urn       = "${var.default_school_urn}"
  http_pass                = "${var.http_pass}"
  http_user                = "${var.http_user}"
  hiring_staff_http_user   = "${var.hiring_staff_http_user}"
  hiring_staff_http_pass   = "${var.hiring_staff_http_pass}"
  benwick_http_user        = "${var.benwick_http_user}"
  benwick_http_pass        = "${var.benwick_http_pass}"
  google_maps_api_key      = "${var.google_maps_api_key}"
  google_analytics         = "${var.google_analytics}"
  rollbar_access_token     = "${var.rollbar_access_token}"
  secret_key_base          = "${var.secret_key_base}"
  rds_username             = "${var.rds_username}"
  rds_password             = "${var.rds_password}"
  rds_address              = "${module.rds.rds_address}"
  es_address               = "${module.es.es_address}"
  aws_elasticsearch_region = "${var.region}"
  aws_elasticsearch_key    = "${module.es.es_user_access_key_id}"
  aws_elasticsearch_secret = "${module.es.es_user_access_key_secret}"
}

module "logs" {
  source = "./terraform/modules/logs"

  environment  = "${terraform.workspace}"
  project_name = "${var.project_name}"
}

module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  environment            = "${terraform.workspace}"
  project_name           = "${var.project_name}"
  slack_hook_url         = "${var.cloudwatch_slack_hook_url}"
  slack_channel          = "${var.cloudwatch_slack_channel}"
  ops_genie_api_key      = "${var.cloudwatch_ops_genie_api_key}"
  autoscaling_group_name = "${module.core.ecs_autoscaling_group_name}"
  pipeline_name          = "${module.pipeline.pipeline_name}"
}

module "pipeline" {
  source = "./terraform/modules/pipeline"

  environment         = "${terraform.workspace}"
  project_name        = "${var.project_name}"
  aws_account_id      = "${var.aws_account_id}"
  github_token        = "${var.github_token}"
  buildspec_location  = "${var.buildspec_location}"
  git_branch_to_track = "${var.git_branch_to_track}"

  registry_name    = "${module.ecs.registry_name}"
  ecs_cluster_name = "${module.ecs.cluster_name}"
  ecs_service_name = "${module.ecs.service_name}"
}

module "rds" {
  source = "./terraform/modules/rds"

  environment        = "${terraform.workspace}"
  project_name       = "${var.project_name}"
  rds_storage_gb     = "${var.rds_storage_gb}"
  rds_instance_type  = "${var.rds_instance_type}"
  rds_engine         = "${var.rds_engine}"
  rds_engine_version = "${var.rds_engine_version[var.rds_engine]}"
  rds_username       = "${var.rds_username}"
  rds_password       = "${var.rds_password}"

  vpc_id                    = "${module.core.vpc_id}"
  default_security_group_id = "${module.core.default_security_group_id}"
}

module "es" {
  source = "./terraform/modules/es"

  environment    = "${terraform.workspace}"
  project_name   = "${var.project_name}"
  instance_count = "${var.es_instance_count}"
  instance_type  = "${var.es_instance_type}"
  es_version     = "${var.es_version}"
  es_domain_name = "${var.project_name}-${terraform.workspace}-default"

  vpc_id                    = "${module.core.vpc_id}"
  default_security_group_id = "${module.core.default_security_group_id}"
}

module "cloudfront" {
  source = "./terraform/modules/cloudfront"

  environment                   = "${terraform.workspace}"
  project_name                  = "${var.project_name}"
  cloudfront_origin_domain_name = "${module.core.alb_dns_name}"
  cloudfront_aliases            = "${var.cloudfront_aliases}"
  cloudfront_certificate_arn    = "${var.cloudfront_certificate_arn}"
}
