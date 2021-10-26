# Exercie 4 : Créer un module

Dans ce TP, nous allons réaliser un module qui permet de créer un bucket S3 ouvert afin d'héberger un site statique. On partira du principe que ce site est composé d'une page `index.html` en guise de page d'accueil, ainsi que d'une page `error.html` pour les cas d'erreur (disponibles dans le dossier `www`).
 
#### 1. Mise en place
Quand on travaille avec des modules, les bonnes pratiques de terraform recommandent de les placer sous le dossier modules à la racine. Ici, un dossier `aws-website-bucket` est déjà créé pour vous.

Commencez par ajouter le fichier `LICENSE` et `README.md`. Pour la license, je vous laisse le choix ;) Mais n'oubliez pas de remplir un peu le README, la doc ça ne fait jamais de mal ! En général, on indique les arguments (variables) qu'accepte votre module.

#### 2. Variables d'entrée
Pour que les développeurs qui utiliseront votre module puisse le personaliser, vous devez indiquer des variables qui seront utilisables en entrée. Dans cet exercice, le seul élément que l'utilisateur pourra modifier est le nom du bucket.

Créez un fichier `variables.tf` dans votre module et définissez une variable qui contiendra le nom du bucket.

#### 3. Resources du module
Afin de réaliser votre bucket, vous devez indiquer les resources à créer dans un fichier `main.tf`. Ajoutez ce fichier à votre module, et ajoutez une ressource `aws_s3_bucket`.

Afin d'héberger un site statique, on s'interessera aux arguments suivant :
* `bucket` : le nom unique de votre bucket
* `acl` : permet de gérer l'accès aux ressources, pour un bucket public on peut le définir sur `public-read`
* `policy` : politique d'accès du bucket, vous pouvez utiliser la policy ci-dessous
* `website` : cet argument prend deux arguments :
    * `index_document` : page à retourner pour l'index
    * `error_document` : page à retourner en cas d'erreur

Policy d'accès *attention à bien remplacer <BUCKET_NAME> par le nom du bucket...*
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::<BUCKET_NAME>/*"
            ]
        }
    ]
}
```

#### 4. Remonter l'information à l'utilisateur
Si vous observez le fichier `outputs.tf` du module racine, vous devriez avoir une idée des outputs à créer dans votre module...

#### 5. Utiliser le module
Une fois l'écriture de votre module terminée, n'oubliez pas de l'appeler dans le module racine (dans le `main.tf`).

Vous pouvez ensuite éxecuter `terraform apply`. 

Si vous n'avez pas touché au fichier `outputs.tf` du module racine, vous pouvez éxecuter la commande suivante :
```
aws s3 cp www/ s3://$(terraform output website_bucket_name)/ --recursive
```
Elle va copier le contenu du dossier www/ dans le bucket.

Si ça fonctionne, rendez vous à l'adresse donnée par terraform afin d'afficher votre page web (testez la page d'erreur également). 

Félicitations, vous venez de créer votre premier module ! Réjouissez vous face à votre réussite... mais pas trop car la formation n'est pas encore terminée !