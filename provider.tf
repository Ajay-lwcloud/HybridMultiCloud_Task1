

//Giving provider information to terraform !

provider "aws" {
region = "ap-south-1"
}


//Making varible for public key !


variable "x" {
  type = string
  default = "Your_Key_Here"
}


//Creation of key !


resource "aws_key_pair" "MY_KEY" {
  key_name   = "ajay_key_2"
  public_key = var.x
}



//Creating security group with own port !


resource "aws_security_group" "customtcp" {
  name        = "MY_SG"
  description = "rule of TCP inbound traffic"
  vpc_id      = "vpc-dcffe2b4"


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
    Name = "Allowing TCP"
  }
}

resource "aws_instance" "web" {
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name        = "ajaykey2"
  security_groups = ["launch-wizard-1"]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/users/nidhi/downloads/ajaykey2.pem")
    host        = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",

    ]
  }

  tags = {
    Name = "MY_OS1"
  }

}

resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "MY_EBS1"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.ebs1.id
  instance_id  = aws_instance.web.id
  force_detach = true
}



//Creating S3 bucket with public access !


resource "aws_s3_bucket" "TERRAFORM_S3" {
  bucket = "bucket-created-from-tf"
  acl    = "public-read"
  versioning {
enabled=true
}
}



//creating S3 bucket_object


resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.TERRAFORM_S3.bucket
  key    = "My_Image"
  acl = "public-read"
  source="C:\\Users\\Desktop\\Task1_Image_Asset.jpg"
  etag = filemd5("C:\\Users\\Desktop\\Task1_Image_Asset.jpg")
}



// creating cloudfront for s3 bucket


resource "aws_cloudfront_distribution" "s3_distribution" {
depends_on = [
   null_resource.nullremote3,
  ]
  origin {
    domain_name = aws_s3_bucket.TERRAFORM_S3.bucket_regional_domain_name
    origin_id   = "my_first_origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "TERRAFORM_IMAGE_IN_CF"
  default_root_object = "My_Image"
    default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my_first_origin"
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "my_first_origin"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my_first_origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE","IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
connection {
        type    = "ssh"
        user    = "ec2-user"
        private_key = file("C:\\Users\\nidhi\\downloads\\ajaykey2.pem")
	host     = aws_instance.web.public_ip
    }
provisioner "remote-exec" {
        inline  = [
            # "sudo su << \"EOF\" \n echo \"<img src='${self.domain_name}'>\" >> /var/www/html/index.html \n \"EOF\""
            "sudo su << EOF",
            "echo \"<center><img src='http://${self.domain_name}/${aws_s3_bucket_object.object.key}'></center>\">> /var/www/html/index.html",
            "EOF"
        ]
    }

}


//Connecting to Instance and Volume,Formatting as well as downloading github code to it !



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:\\Users\\nidhi\\downloads\\ajaykey2.pem")
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Ajay-lwcloud/HybridMultiCloud_Task1.git /var/www/html",
    ]
  }
}


//Launching web Browser(Firefox) when coded infrastructure is successfully run !



resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,aws_cloudfront_distribution.s3_distribution
  ]

	provisioner "local-exec" {
	    command = "start firefox  ${aws_instance.web.public_ip}"
  	}
}
