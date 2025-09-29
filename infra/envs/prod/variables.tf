variable "region" { 
    type = string
    default = "ap-south-1" 
 }

variable "vpc_cidr" { 
    type = string 
    default = "10.0.0.0/16" 
}

variable "github_repo" { 
    description = "org/repo for GitHub Actions" 
    type = string 
}

variable "image_tag" { 
    description = "image tag to deploy (commit SHA)" 
    type = string 
}

variable "container_port" { 
    type = number 
    default = 8000 
}

variable "desired_count" { 
    type = number 
    default = 2 
}

variable "task_cpu" { 
    type = string 
    default = "256" 
}

variable "task_memory" { 
    type = string 
    default = "512" 
}
