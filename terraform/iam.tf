data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: used by ECS itself to pull the image and write logs.
resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: the permissions your own code gets. Empty for now.
# Add policies here later, for example read access to one DynamoDB table.
resource "aws_iam_role" "task" {
  name               = "${var.project_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

# Lets ECS (not your code) read the Django secret key when it starts a task.
data "aws_iam_policy_document" "read_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.django_key.arn]
  }
}

resource "aws_iam_role_policy" "execution_read_secret" {
  name   = "read-django-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secret.json
}
