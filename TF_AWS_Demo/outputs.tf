

output "Pri_ec2-Public-IP" {
  value = aws_instance.sk_pri_ec2.public_ip
}

output "Sec_ec2-Public-IPs" {
  value = {
    for sk_ec2_instance in aws_instance.sk_sec_ec2 :
    sk_ec2_instance.id => sk_ec2_instance.public_ip
  }
}

