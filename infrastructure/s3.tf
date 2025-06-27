resource "random_string" "s3_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "kubeflow_pipelines" {
  bucket = "${var.s3_bucket_name}-${random_string.s3_suffix.result}"

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "kubeflow_pipelines" {
  bucket = aws_s3_bucket.kubeflow_pipelines.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "kubeflow_pipelines" {
  depends_on = [aws_s3_bucket_ownership_controls.kubeflow_pipelines]

  bucket = aws_s3_bucket.kubeflow_pipelines.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "kubeflow_pipelines" {
  bucket = aws_s3_bucket.kubeflow_pipelines.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kubeflow_pipelines" {
  bucket = aws_s3_bucket.kubeflow_pipelines.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kubeflow_pipelines" {
  bucket = aws_s3_bucket.kubeflow_pipelines.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "kubeflow_pipelines" {
  bucket = aws_s3_bucket.kubeflow_pipelines.id

  rule {
    id = "cleanup-old-artifacts"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    status = "Enabled"
  }
}

# IAM policy for Kubeflow Pipelines to access S3
resource "aws_iam_policy" "kubeflow_pipelines_s3" {
  name        = "kubeflow-pipelines-s3-access"
  description = "IAM policy for Kubeflow Pipelines to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kubeflow_pipelines.arn,
          "${aws_s3_bucket.kubeflow_pipelines.arn}/*"
        ]
      }
    ]
  })
}

# Output the S3 bucket name for reference
output "kubeflow_pipelines_bucket" {
  description = "S3 bucket for Kubeflow Pipelines artifacts"
  value       = aws_s3_bucket.kubeflow_pipelines.bucket
}
