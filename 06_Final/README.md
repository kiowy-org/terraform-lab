# Exercice 6 : Infrastructure AWS complète
Vous y êtes, l'exercice complet ! Courage, car le but de cet exercice est de réaliser l'infrastructure complète d'un site web (PHP) avec une base de donnée (Mysql RDS) avec haute disponibilité sur deux zones.

Le code de l'application se trouve dans le dossier `src/`, c'est une application PHP très simple. La seule section interessante est dans `db-config.php` qui contient les variables d'accès à la base (nous verrons comment les modifier plus tard). 

Nous allons réaliser l'infrastructure niveaux par niveaux (ou plutot... modules par modules !). Le but étant d'encapsuler les ressources dens des modules. Parcourez les fichier, les ressources sont déjà présentes, mais vous devez les configurer, et ajouter les variables/outputs qui conviennent.

*NOTE* Pour la majorité des ressources, essayez d'ajouter un tag `Name` afin d'identifier les éléments plus facilement dans la console, utilisez également la variable `var.prefix_name` afin d'assurer des nom uniques.

### 1. Module VPC (réseau)
Commencons par la base : le réseau. Dans AWS, toutes les ressources que nous allons créer doivent êtres isolées au sein d'un VPC (Virtual Private Cloud).

Dans votre dossier, vous pouvez créer la structure classique d'un module ;) Ajoutez ensuite un VPC. Nous allons utiliser le réseau `10.0.0.0/16` par défaut, mais laissez quand même la possibilité à l'utilisateur de changer si il le souhaite !

À part le CIDR, je vous donne la config du VPC afin que notre projet fonctionne :
```
instance_tenancy     = "default"
enable_dns_support   = true
enable_dns_hostnames = true
enable_classiclink   = false
```
N'oubliez pas également le tag `Name`, ça permet de mieux s'y retrouver dans l'interface AWS.

Comme nous souhaitons déployer une infra en haute disponibilité, nous avons besoin de répartir le réseau sur deux zones de disponibilité AWS (`eu-west-3a` et `eu-west-3b` par défaut, mais laissez la possibilité de changer), mais également nous devons pour chaque zone avoir un sous réseau privé et public, soit 4 sous réseaux en tout.
Par défaut, on peut imaginer le découpage suivant :
```
10.0.1.0/24 -> Public, AZ1
10.0.2.0/24 -> Public, AZ2
10.0.3.0/24 -> Private, AZ1
10.0.4.0/24 -> Private, AZ2
```
Bien évidemment, il faut laisser à l'utilisateur de notre module la possibilité de changer si il le souhaite.

Ajoutez les sous réseaux (`subnet`) à la configuration terraform, essayez de ne pas vous répéter au maximum (`count` peut surement vous aider). Veillez à bien assigner la zone de disponibilité au bon subnet.
*Important*, la notion de subnet privé ou public se défini avec l'argument `map_public_ip_on_launch`. Si c'est `true`, alors le subnet est publique.

Maintenant que les sous-réseaux sont en place, occupons nous du routage. Pour le réseau public, nous devons laisser entrer le traffic Internet.

Pour cela, vous devez d'abord créer une Gateway Internet (`internet_gateway`). N'oubliez pas de bien l'attacher à notre VPC.

Ensuite, vous devez créer une route par défaut (`0.0.0.0/0 -> Gateway`) pour les subnets publiques. Pour cela, créez d'abord une `route_table` avec les options qui vont bien ! Ensuite, pour attacher cette règle à nos subnets, utilisez deux `route_table_association` (là encore, essayez de ne pas vous répeter).

Concernant nos subnets privés, bien que le traffic entrant ne soit pas autorisé, il faut que nos machines puissent accéder à internet. Pour cela il nous faudra une IP publique, une passerelle NAT, une route et une association de route !

Créez une ip (`eip`) pour la passerelle NAT. Mettez l'argument `vpc` à `true`.

Créer une `nat_gateway`, n'oubliez pas que la paserrelle doit se trouver elle dans un subnet public !

Ensuite, à l'aide d'une `route_table`, indiquez une règle `0.0.0.0/0` vers notre gateway NAT.

Efin, associez les subnets privés avec votre `route_table`.

Voilà pour le réseau ! N'ouvbliez pas d'exposer quelques informations (id de vpc, de subnets...) depuis votre module, nous allons en avoir besoin ailleurs !


### 2. Bucket S3 pour stocker nos sources
Nous souhaitons que nos serveurs web puissent scaler (grâce à l'auto scaling group !). Nous devons donc trouver un moyen d'istaller les sources de notre application dès qu'un nouveau serveur démarre !

Plusieurs possibilités existent, proposez une stratégie pour réaliser cela avant de l'implémenter !

### 3. Créer notre pool de serveurs web en haute disponibilité
Attaquons nous à la partie la plus longue ! Les serveurs web. Le principe est simple et repose sur deux composants : un load balancer (Amazon Load Balancer ou ALB) qui dirige le traffic depuis internet vers notre pool de machine. Ce pool est géré dynamiquement par un Auto Scaling Group (ASG) charger d'ajouter ou de retirer des VM en fonction de la charge.

Commencons tout d'abord par gérer les règles de pare feu. On doit autoriser le traffic entrant sur le port 80 (ou un autre, au choix de l'utilisateur) à traverser le load balancer. 
On créé pour cela un `security_group`, avec les règles suivantes :
```hcl
egress { # On autorise tout en sortie
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # On autorise que le port de l'application en entrée
    from_port   = <PORT APP>
    to_port     = <PORT APP>
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
```

On va ensuite créer un second `security_group` pour gérer le traffic atteignant nos VM. On va autoriser toute les sorties, mais seulement le port 22 en entrée, ainsi que le traffic provenant du load balancer.
```hcl
egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = <PORT APP>
    to_port         = <PORT APP>
    protocol        = "tcp"
    security_groups = [<ID DU SECURITY GROUP DU LOAD BALANCER>]
  }
```

Profitons en pour enregistrer notre clé publique sur AWS, nous pourrons nous connecter aux instances si besoin. Vous pouvez générer une clé RSA avec `ssh-keygen` et la stocker dans le dossier `keys/` du projet. Ajoutez ensuite une `key_pair` à votre config, et indiquez le fichier de public key (on laissera le path configurable par l'utilisateur).

**Passons à notre pool de VM**. Afin de le représenter, nous devons créer un objet `launch_configuration`. En effet, l'ASG sera chargé de créer et détruire des VM automatiquement, nous devons donc lui fournir le "modèle" qui permettra de créer des VM, via le Launch Configuration.

Indiquez un `name_prefix` de votre choix, l'`image_id` et l'`instance_type` seront passé en paramètre à notre module. N'oubliez pas de lier votre clé publique aux instances, ainsi qu'attacher le `security_group` qui va bien. Laissez la possibilité de définir les arguements `user_data` et `ima_instance_profile`.

Ah et n'oubliez pas d'indiquer à terraform que si il doit détruire puis recréer cette ressource, il doit d'abord en créer une nouvelle (pour éviter les interruptions de service).

Nous y sommes ! Créons notre AutoScaling Group (ASG). Ajoutez un `autoscaling_group` à votre config. Comme c'est un objet assez conséquen, je vous liste les arguments intéressants :
```hcl
  vpc_zone_identifier       = <LISTE DES IDS DES SUBNETS PRIVES>
  launch_configuration      = <NOM DE LA LAUNCH_CONFIGURATION>
  min_size                  = # Au choix de l'utilisateur
  desired_capacity          = # Au choix de l'utilisateur
  max_size                  = # Au choix de l'utilisateur
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [ <ARN DU TARGET GROUP CI-DESSOUS> ]
  force_delete              = true
```

Enfin, nous devons définir le groupe d'instance via un `lb_target_group`. Indiquez un `name`, le `port` (80 par défaut), le `protocol` (http par défaut) et liez l'id de votre vpc.

Ajoutez un `lb_listener` qui spécifie l'entrée de votre load balancer, avec la configuration suivante :
```hcl
  load_balancer_arn  = # attribut arn du load balancer
  port               = <PORT APP>
  protocol           = <PORT PROTOCOLE>

  default_action {
    type             = "forward"
    target_group_arn = # attribut arn du target group
  }
```

Voilà ! Vos serveurs web sont fin prêts !


### 4. RDS : Base de donnée managée par AWS
Nous voulons stocker les données de notre application dans une base gérée par AWS (appelé RDS)

Commencons par les règles de pare-feu. Le `security_group` dois nous permettre d'accéder à la base (port 3306) depuis les VM du pool de noeud. Nous allons autoriser le security group correspondant à accéder à nos instances RDS.
Utilisez les règles suivantes :
```hcl
ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = <ID SECURITY GROUP VM>
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
```

Créons ensuite un subnet spécial pour la base de données, il faut l'attacher à nos subnets privées (via l'argument `subnet_ids`).

Nous allons ensuite utiliser une ressource `db_parameter_group` qui permet de gérer les options de la base de données (ici MariaDB). La seule options que nous allons définir est la `family` sur la valeur `mariadb10.1`. Cela correspond à la version de la base dans AWS.

Nous pouvons enfin créer notre instance de base de données (`db_instance`). Sa configuration est assez fournie, je vous donne la trame à suivre :
```hcl
  allocated_storage         = # paramètre du module
  engine                    = "mariadb"
  engine_version            = # paramètre du module
  instance_class            = # paramètre du module
  identifier                = "mariadb"
  name                      = # paramètre du module
  username                  = # paramètre du module
  password                  = # paramètre du module
  db_subnet_group_name      = <NAME SUBNET DN>
  parameter_group_name      = <NAM PARAMETER GROUP>
  multi_az                  = # paramètre du module
  vpc_security_group_ids    = [<ID SECURITY GROUP DB>]
  storage_type              = # paramètre du module
  backup_retention_period   = # paramètre du module
  final_snapshot_identifier = "${var.prefix_name}-mariadb-snapshot"
  tags = {
    Name = "${var.prefix_name}-mariadb"
  }
```

Notre base est configurée, il ne nous reste plus qu'à s'occuper du monitoring

### 5. La cerise sur le gateaux : le monitoring !
Nous allons utiliser CloudWatch, l'outil de monitoring d'AWS. Il va nous permettre d'agir en fonction d'évènements sur l'infra, notamment de déclencher le scale up et down en fonction de l'utilisation du CPU.

Nous définissons tout d'abord un `autoscaling_policy`. Cet objet défini une action à prendre quand il est déclenché (ici déclencher un scale up de l'ASG).
```hcl
  name                   = <NAME>
  autoscaling_group_name = <NAME DE L'ASG>
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
```

Ensuite nous définissons la métrique à observer (le cpu) ainsi que le seuil de déclenchement de l'alarme.
  alarm_name          = "${var.prefix_name}-cpu-scaleup"
  alarm_description   = "${var.prefix_name}-cpu-scaleup"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = # Fourni par l'utilisateur du module (en %)

  dimensions = {
    "AutoScalingGroupName" = <NAME DE L'ASG>
  }

  actions_enabled = true
  alarm_actions   = [<ARN DE LA POLICY>]

En vous basant sur les deux objets que nous venons de crééer, configurez la policy et la métrique pour le scale down (on utilisera `LessThanOrEqualToThreshold` en tant que `comparison_operator`).

### 6. Le module racine
Vous y êtes enfin, plus qu'à cabler l'ensemble dans le `main.tf` principal. Les variables d'entrée du root module sont déjà définies, vous n'avez pas à en ajouter. Si un élément n'est pas fournis par l'utilisateur, voiçi les valeurs par défaut à utiliser pour vos modules :
```
cidr de votre VPC             : 10.0.0.0/16
cidrs de vos subnets public   : 10.0.1.0/24, 10.0.2.0/24
cidrs de vos subnets privés   : 10.0.3.0/24, 10.0.4.0/24
zones de disponibilité        : eu-west-3a, eu-west-3b
port du serveur web           : 80
protocole du serveur web      : HTTP
type d'instance               : t2.micro
instances minimum             : 2
instances désirées            : 2
instances max                 : 3
stockage db                   : 5
version mariadb               : 10.1.34
type instance mariadb         : db.t2.small
nom de la db                  : blog
multi zone                    : true
type de stockage              : gp2
période de rétention de kbcp  : 1
cpu minimum                   : 5
cpu maximum                   : 80
```

Une fois que tout est assemblé, plus qu'à faire un dernier `terraform apply`, et profiter du travail accompli ! Félicitations !

































## Annexe : User Data
Si vous avez lu jusqu'ici, félicitations, ci-dessous le code utilisé dans l'argument `user_data` afin d'installer le serveur web, copier le code, charger les données en base et insérer les identifiants de DB dans le code PHP. Reste à compléter l'interpolations ;)
```hcl
      #!/bin/bash
      sudo apt-get update -y
      sudo apt-get install -y apache2 awscli mysql-client php php-mysql
      sudo systemctl start apache2
      sudo systemctl enable apache2
      sudo rm -f /var/www/html/index.html
      sudo aws s3 sync  s3://<BUCKET NAME>/ /var/www/html/
      mysql -h <DB HOST> -u <DB USERNAME> -p<DB PASSWORD> < /var/www/html/articles.sql
      sudo sed -i 's/##DB_HOST##/<DB HOST>/' /var/www/html/db-config.php
      sudo sed -i 's/##DB_USER##/<DB USERNAME>/' /var/www/html/db-config.php
      sudo sed -i 's/##DB_PASSWORD##/<DB PASSWORD>/' /var/www/html/db-config.php
```