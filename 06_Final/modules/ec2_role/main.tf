# IAM role
resource "aws_iam_role" "" {
}

# IAM profile for EC2 instances at startup
resource "aws_iam_instance_profile" "" {
}


# Role policy
resource "aws_iam_role_policy" "s3-mybucket-role-policy" {
}