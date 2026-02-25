aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 076224130336.dkr.ecr.us-east-1.amazonaws.com
sudo docker build -t deontevanterpool .                                                                                                  
docker tag deontevanterpool:latest ${account_id}.dkr.ecr.${region}.amazonaws.com/deontevanterpool-ecr-repo:latest
docker push ${account_id}.dkr.ecr.${region}.amazonaws.com/deontevanterpool-ecr-repo:latest

