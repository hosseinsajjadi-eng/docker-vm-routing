# Server-1 configuration
# Server-1 IP
# enp0s3 = 10.0.2.4/24
# Enable IP Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
# Apply sysctl configuration
sudo sysctl --system
# Check
sysctl net.ipv4.ip_forward


# Docker Network on Server-1
docker network create \
  --driver bridge \
  --subnet 192.168.2.0/24 \
  --gateway 192.168.2.1 \
  -o com.docker.network.bridge.trusted_host_interfaces=enp0s3 \
  network1
# Check Docker network
docker network inspect network1
# Check interfaces
ip -br a

# Run Container on Server-1
docker run -d \
  --name nginx \
  --network network1 \
  --ip 192.168.2.2 \
  nginx:latest


# Check container IP
docker inspect nginx 

# iptables on Server-1


sudo iptables -A FORWARD \
  -i enp0s3 \
  -o br-b74c83286b4e \
  -s 10.0.2.0/24 \
  -d 192.168.2.0/24 \
  -j ACCEPT

sudo iptables -A FORWARD \
  -i br-b74c83286b4e \
  -o enp0s3 \
  -s 192.168.2.0/24 \
  -d 10.0.2.0/24 \
  -j ACCEPT

# Check firewall rules
sudo iptables -L FORWARD -n -v --line-numbers


# Server-2 configuration
# Server-2 IP
# enp0s3 = 10.0.2.5/24
# Add route to Docker network through Server-1
sudo ip route replace \
  192.168.2.0/24 \
  via 10.0.2.4 \
  dev enp0s3
# Check route
ip route
# Check exact route
ip route get 192.168.2.2

