provider "aws" {
  region     = "ap-south-1"
  profile    = "task171"
}

resource "aws_security_group" "allow_my_http" {
  name        = "launch-wizard-7"
  description = "Allow my HTTP SSH inbound traffic"
  vpc_id      = "vpc-f2c6d99a"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "httpsecurity"
  }
}

resource "aws_s3_bucket" "job171" {
  bucket = "job171" 
  acl    = "public-read"
  tags = {
    Name        = "job171"
  }
  versioning {
	enabled =true
  }
}

resource "aws_s3_bucket_object" "s3object" {
  bucket = "${aws_s3_bucket.job171.id}"
  key    = "awscc.jpeg"
  source = "/home/nithish/Pictures/awscc.jpeg"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "This is origin access identity"
}

resource "aws_cloudfront_distribution" "imgcf" {
    origin {
        domain_name = "job171.s3.amazonaws.com"
        origin_id = "S3-job171" 


        s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
       
    enabled = true
      is_ipv6_enabled     = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-job171"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 10
        max_ttl = 30
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

resource "aws_instance" "os" {
  ami               = "ami-0447a12f28fddb066"
  instance_type     = "t2.micro"
  key_name          = "hcc81"
  security_groups   = [ "launch-wizard-7" ]
	

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/home/nithish/Downloads/hcc81.pem")
    host        = "${aws_instance.os.public_ip}"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php  git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd"
    ]
  }

  tags = {
      Name = "myfirstos"
  }
}

resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = aws_instance.os.availability_zone
  size              = 1

  tags = {
    Name = "myfirstos"
  }
}


resource "aws_volume_attachment" "Ebs_Att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.os.id
  force_detach = true
}

output "myos_ip" {
  value = aws_instance.os.public_ip
}


resource "null_resource" "nullremote1"  {

  depends_on = [
    aws_volume_attachment.Ebs_Att,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/nithish/Downloads/hcc81.pem")
    host     = aws_instance.os.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vyshnavi7120/multicloud.git /var/www/html/"
    ]
  }
}








	



