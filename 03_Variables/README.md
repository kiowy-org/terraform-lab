# Exercie 3 : Utiliser les variables et les outputs
Nous allons refactorer le code réalisé lors de l'exercice précédent afin de le rendre un peu plus flexible grâce aux variables.

**N'oubliez pas de supprimer l'infrastructure créée lors du TP précédent via `terraform destroy`**

#### 1. Mise en place du projet
Vous pouvez utiliser ce dossier comme base, n'oubliez pas d'éxecuter `terraform init` ;)

#### 2. Première variable : votre préfixe
Pour commencer en douceur, vous allez définir une variable de type `string` contenant un préfixe de votre choix, vous pourrez ensuite l'utiliser tout au long de la formation dans le nom des ressources afin de les rendre unique.

Commencez par créer un fichier `variables.tf` et déclarez une variable de type `string`, appelée `prefix`. N'oubliez pas la description de votre variable afin qu'un autre développeur comprenne ce que c'est.

Ensuite, éditez `main.tf` afin que le tag `Name` de l'instance EC2 soit `<prefix>-instance`. Utilisez la syntaxe d'interpolation `"${var.<NOM_VARIABLE>}"` pour cela.

#### 3. Spécifier une région, mais seulement européenne
Afin de rendre notre code plus flexible, nous souhaitons laisser le choix dans la région, mais pas trop non plus ! RGPD oblige, il faut que la région soit parmis les suivantes : 
```
eu-west-1
eu-west-2
eu-south-1
eu-west-3
eu-north-1
eu-central-1
```

Déclarez la variable `aws_region`, avec comme paramètre par défaut la région `eu-west-3` et n'acceptant que les régions ci-dessus (indice : [il existe la fonction `contains`](https://www.terraform.io/docs/language/functions/contains.html)).

Ajoutez ensuite la référence à cette variable dans l'argument `region` du provider AWS.

#### 4. Spécifier les AMIs en fonction des régions
Pour simplifier la vie des utilisateurs de notre code Terraform (ou la notre...), nous souhaitons fixer les AMIs à utiliser. Cependant sur AWS, l'AMI ID dépend de la région.

Nous allons utiliser une `local` afin de spécifier la liste des AMI par région grâce à une map.

```
locals {
    amis_by_region = {
        "eu-west-1"    = "ami-0f617e4136f03b9ad"
        "eu-west-2"    = "ami-0d21c64d5074a949a"
        "eu-south-1"   = "ami-008c11e98baa0896c"
        "eu-west-3"    = "ami-06d79c60d7454e2af"
        "eu-north-1"   = "ami-01cf7e0f481ff30b4"
        "eu-central-1" = "ami-0b4b0a5bd04aec558"
    }
}
```

Afin que terraform "choissise" la bonne AMI, vous devez définir une autre `local` basée sur la variable `aws_region`. Vous pourrez ensuite référencer cette `local` dans l'argument `ami` de l'instance EC2.

#### 5. Afficher l'IP Publique de l'instance

Afin d'afficher l'IP de notre instance EC2, nous allons ajouter un output. Créez un fichier `outputs.tf`. Ajoutez un `output` appelé `public_ip` qui affiche l'argument `public_ip` de l'instance EC2.

#### 6. Ajouter des variables et éxecuter

Pour terminer, assignez des valeurs aux variables (vous pouvez tenter un `terraform apply` sans variables pour voir le comportement de la commande).

Vérifiez également que les valeurs sont bien validées par Terraform si vous indiquez une région non autorisée.