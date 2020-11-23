provider "aws"{
    region = var.region
}

locals {

  filename    = var.local_existing_package != null ? var.local_existing_package : (var.store_on_s3 ? null : element(concat(data.external.archive_prepare.*.result.filename, [null]), 0))
  was_missing = var.local_existing_package != null ? ! fileexists(var.local_existing_package) : element(concat(data.external.archive_prepare.*.result.was_missing, [false]), 0)


  s3_bucket         = var.s3_existing_package != null ? lookup(var.s3_existing_package, "bucket", null) : (var.store_on_s3 ? var.s3_bucket : null)
  s3_key            = var.s3_existing_package != null ? lookup(var.s3_existing_package, "key", null) : (var.store_on_s3 ? element(concat(data.external.archive_prepare.*.result.filename, [null]), 0) : null)
  s3_object_version = var.s3_existing_package != null ? lookup(var.s3_existing_package, "version_id", null) : (var.store_on_s3 ? element(concat(aws_s3_bucket_object.lambda_package.*.version_id, [null]), 0) : null)

}

resource "aws_lambda_function" "this" {
  count = var.create && var.create_function && ! var.create_layer ? 1 : 0

  function_name                  = var.function_name
  description                    = var.description
  role                           = var.create_role ? aws_iam_role.lambda[0].arn : var.lambda_role
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  layers                         = var.layers
  timeout                        = var.lambda_at_edge ? min(var.timeout, 5) : var.timeout
  publish                        = var.lambda_at_edge ? true : var.publish
  kms_key_arn                    = var.kms_key_arn

  filename         = local.filename
  source_code_hash = (local.filename == null ? false : fileexists(local.filename)) && ! local.was_missing ? filebase64sha256(local.filename) : null

  s3_bucket         = local.s3_bucket
  s3_key            = local.s3_key
  s3_object_version = local.s3_object_version

  dynamic "environment" {
    for_each = length(keys(var.environment_variables)) == 0 ? [] : [true]
    content {
      variables = var.environment_variables
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn == null ? [] : [true]
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode == null ? [] : [true]
    content {
      mode = var.tracing_mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? [true] : []
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_arn != null && var.file_system_local_mount_path != null ? [true] : []
    content {
      local_mount_path = var.file_system_local_mount_path
      arn              = var.file_system_arn
    }
  }

  tags = var.tags

  depends_on = [null_resource.archive, aws_s3_bucket_object.lambda_package]
}