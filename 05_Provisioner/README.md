# Exercie 5 : Provisioner une instance EC2

Le but de ce TP est de vous présenter comment provisionner une instance EC2 via le `provisioner` `remote-exec`. Nous allons installer un serveur web apache (comme sur les TP précédents), mais cette fois sans utiliser l'argument `user_data`.

#### 1. Générer une clé
Afin que le provisionner puisse s'éxecuter, terraform doit être en mesure de se connecter via ssh à votre instance. Vous devez donc générer une clé, à l'aide des instructions suivantes.
**ATTENTION, ne supprimez pas vos clé déjà existantes... nommez bien la clé `terraform`**
```bash
ssh-keygen -t rsa
    
Generating public/private rsa key pair.
Enter file in which to save the key (/home/hatim/.ssh/id_rsa): ./terraform
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
```

Enfin, modifiez les permission de votre clé :
```bash
chmod 400 ./terraform
```

#### 2. Autoriser la clé auprès de l'instance
Afin d'enregistrer votre clé auprès de l'instance, vous devez lui fournir votre clé publique. Pour cela vous alez tout d'abord devoir créer une resource `aws_key_pair` à partir de votre fichier `terraform.pub`. [La documentation de cette resource se trouve ici](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair)

N'oubliez pas de référencer votre clé auprès de la ressource EC2 via l'argument `key_name`.

#### 3. Ajouter une connection
Pour que terraform se connecte à votre instance, vous devez indiquer la configuration dans un block `connection`.
Ajoutez ce block à l'instance EC2, en sachant que le nom d'utilisateur est `ubuntu` et que la fonction qui permet d'inclure un fichier est `file(<path>)`

#### 4. Ajouter le provisioner
Enfin, vous pouvez ajouter votre block provisioner à l'instance EC2. Il reprend simplement le code du TP 2 et 3 pour l'installation de Apache.

```hcl
provisioner "remote-exec" {
        inline = [
          "sudo apt-get -f -y update",
          "sudo apt-get install -f -y apache2",
          "sudo systemctl start apache2",
          "sudo systemctl enable apache2",
          "sudo sh -c 'echo \"<h1>Hello devopssec</h1>\" > /var/www/html/index.html'",
        ]
    }
```

Éxecutez terraform apply, récupérez l'adresse IP publique de l'instance (`terraform show`) et vérifiez que vous pouvez bien accéder au site web !