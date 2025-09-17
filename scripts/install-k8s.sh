#!/usr/bin/env bash
set -euo pipefail

echo "[Step 0] Update system"
sudo apt update -y
sudo apt upgrade -y

echo "[Step 1] Install dependencies"
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

echo "[Step 2] Install containerd"
sudo apt install -y containerd
sudo systemctl enable --now containerd

echo "[Step 2.1] Configure containerd defaults"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo systemctl restart containerd

echo "[Step 3] Add Kubernetes repo (pkgs.k8s.io v1.30)"
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[Step 4] Install kubeadm, kubelet, kubectl"
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[Step 5] Initialize Kubernetes cluster"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "[Step 6] Configure kubectl for user: $USER"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[Step 7] Allow workloads on control-plane (single-node)"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "[Step 8] Install Flannel CNI"
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "✅ Kubernetes installation complete."
echo "Run 'kubectl get nodes' to verify."

