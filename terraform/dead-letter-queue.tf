resource "aws_sqs_queue" "dead_letter_queue" {
  name = "dead_letter_queue"
  max_message_size = 2048
}
