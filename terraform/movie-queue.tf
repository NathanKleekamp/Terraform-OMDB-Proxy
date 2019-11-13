resource "aws_sqs_queue" "movie_queue" {
  name = "movie_queue"
  max_message_size = 2048
  message_retention_seconds = 86400
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter_queue.arn}\",\"maxReceiveCount\":4}"
}
