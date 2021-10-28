# Security group of the db
resource "aws_security_group" "" {

}

# Subnets of the db
resource "aws_db_subnet_group" "mariadb-subnet" {
  
}

# Parameters of the db (mariadb)
resource "aws_db_parameter_group" "mariadb-parameters" {

}

# Db instance
resource "aws_db_instance" "mariadb" {

}