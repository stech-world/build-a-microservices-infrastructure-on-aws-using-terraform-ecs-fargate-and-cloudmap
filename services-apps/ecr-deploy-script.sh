aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 248581660709.dkr.ecr.eu-west-1.amazonaws.com



docker build -t uno ./uno
# docker buildx build --platform=linux/amd64 -t uno ./uno        !!In case you use apple m1 chip use this command instead of the first!!
docker tag uno 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-uno:v1
docker push 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-uno:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_uno_td_service --force-new-deployment



docker build -t due ./due
# docker buildx build --platform=linux/amd64 -t due ./due        !!In case you use apple m1 chip use this command instead of the first!!
docker tag due 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-due:v1
docker push 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-due:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_due_td_service --force-new-deployment



docker build -t tre ./tre
# docker buildx build --platform=linux/amd64 -t tre ./tre        !!In case you use apple m1 chip use this command instead of the first!!docker tag tre 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-tre:v1
docker push 248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-tre:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_tre_td_service --force-new-deployment


