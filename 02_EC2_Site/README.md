# Exercie 2 : Infrastructure EC2 pour un site web
Dans cet exercice, nous allons déployer une infrastructure AWS plus conséquente qu'un bucket S3. Le but est d'héberger une page web sur une instance EC2 et de l'exposer à l'extérieur.

## Partie 1
**N'oubliez pas de supprimer l'infrastructure crée lors du TP précédent via `terraform destroy`**

#### 1. Mise en place du projet
Créez un nouveau dossier qui servira de base à votre projet terraform. Dans ce dossier, créez un fichier `terraform.tf` avec le contenu suivant :
```hcl
# terraform.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.63.0"
    }
  }

  required_version = "1.0.9"
}
```

Créez un fichier `providers.tf` avec le contenu suivant :
```hcl
# providers.tf
provider "aws" {
    region = "eu-west-3"
    access_key = "<votre-access-key>"
    secret_key = "<votre-secret-key"
}
```
Enfin, ajoutez un fichier `main.tf` vierge pour le moment.

#### 2. Création de l'instance EC2
Nous allons tout d'abord ajouter à notre projet une instance EC2. Nous utiliserons ici une instance de type `t2.micro` avec l'AMI `ami-03e15a55e7067db82` (Ubuntu 20.04 LTS).

Ajoutez une ressource de type `aws_instance` dans le fichier `main.tf` grâce aux informations ci-dessus, ainsi qu'à la [documentation terraform correspondante](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance).

Pour valider, vérifiez que terraform va bien créer votre instance grâce à la commande `terraform plan`.
*(Si terraform râle, rappelez vous les commandes du TP précédent pour INITialiser le projet...)*

Si le plan vous convient, créez l'instance avec `terraform apply`.

#### 3. Un peu de personalisation
Pour l'instant, l'instance que vous venez de créer est difficilement identifiable. Pour lui ajouter un nom, vous pouvez ajouter un tag `Name` à votre ressource.

Vérifiez que terraform va uniquement modifier votre ressource (symbole `~`) et appliquez les chagements avec `terraform apply`

#### 4. Installons notre serveur web
**Plusieurs solutions existent pour configurer notre instance** : générer une image AMI avec sa configuration, utiliser un outil comme Ansible par exemple. Ici, nous allons spécifier un script à éxecuter au démarrage de notre instance, via l'attribut `user_data`.


```shell
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
```

Ajoutez le script ci-dessus à l'instance grâce à l'attribut `user_data`. Le HCL support la notation [Heredoc](https://fr.wikipedia.org/wiki/Here_document).
```hcl
# ... aws_instance {
user_data = <<-EOF
	#!/bin/bash
        sudo apt-get update
        sudo apt-get install -y apache2
        sudo systemctl start apache2
        sudo systemctl enable apache2
        sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
    EOF
# ... }
```

Validez et déployez les changements (vous connaissez les commandes désormais ;))

Voilà ! Votre instance EC2 est déployée, cependant, il manque encore quelques éléments afin d'accéder à votre page web depuis internet.



## Partie 2

#### 1. Configuration réseau
Afin que le traffic depuis internet vers notre instance sur le port 80 puisse passer, nous allons créer un `SecurityGroup`.

Ajoutez la ressource suivante à votre projet :
```hcl
resource "aws_security_group" "instance_sg" {
    name = "terraform-test-sg"

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

Vous devez ensuite attribuer cette règle à l'instance EC2. Pour cela, il faut référencer le `SecurityGroup` par son attribut `id` dans l'argument `vpc_security_group_ids`de votre instance EC2.

Modifiez donc votre instance en conséquence, à noter que l'argument `vpc_security_group_ids` attend une liste d'id de `SecurityGroup`.

> Indice : On peut définir une liste avec la syntaxe `[ELEM1, ELEM2, ...]`

Exécutez vos modifications, vérifiez ce que terraform réaliser afin de prendre en compte vos modifications.

#### 2. Accès à l'instance

Votre instance est créée avec le bon groupe, il ne vous reste plus qu'à y accéder. Pour cela vous avez besoin de l'IP publique. 

Vous pouvez l'obtenir de différente manière (ui, cli) et notament grâce à Terraform via la commande `terraform state show`. Nous verrons plus tard comment afficher certaines informations lors de l'éxecution du code Terraform via les *outputs*.