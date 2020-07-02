resource "aws_lb" "eks-test" {
  name               = "eks-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.pilot-cluster-SG.id}"]
  subnets            = ["${aws_subnet.pilot.*.id}"]

  enable_deletion_protection = false

}

resource "aws_lb_target_group" "eks-test-tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.pilot-vpc.id}"
}

resource "aws_lb_target_group_attachment" "eks-node-test" {
  target_group_arn = "${aws_lb_target_group.eks-test-tg.arn}"
  target_id        = "${aws_eks_node_group.pilot-node-sg.id}"
  port             = 80
}
