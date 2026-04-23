aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 076224130336.dkr.ecr.us-east-1.amazonaws.com
sudo docker build -t deontevanterpool .                                                                                                  
docker tag deontevanterpool:latest 076224130336.dkr.ecr.us-east-1.amazonaws.com/deontevanterpool-ecr-repo:latest
docker push 076224130336.dkr.ecr.us-east-1.amazonaws.com/deontevanterpool-ecr-repo:latest

sudo docker build -f Dockerfile.caddy -t caddy .
docker tag caddy:latest 076224130336.dkr.ecr.us-east-1.amazonaws.com/caddy:latest
docker push 076224130336.dkr.ecr.us-east-1.amazonaws.com/caddy:latest
