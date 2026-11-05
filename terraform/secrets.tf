# Terraform generates the Django SECRET_KEY, so you never type or commit it.
# Note: the value is stored in Terraform state, which is why the S3 state bucket is encrypted.
resource "random_password" "django_key" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "django_key" {
  name                    = "${var.project_name}/django-secret-key"
  recovery_window_in_days = 0 # delete immediately on destroy, so re-applying later does not clash
}

resource "aws_secretsmanager_secret_version" "django_key" {
  secret_id     = aws_secretsmanager_secret.django_key.id
  secret_string = random_password.django_key.result
}
