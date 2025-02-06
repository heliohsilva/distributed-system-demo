export KUBECONFIG="$HOME/.kube/config"

minikube start --cpus='6' --gpus='all' --memory='6096'

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait --generate-name -n gpu-operator --create-namespace nvidia/gpu-operator

kubectl create -n gpu-operator -f configmap.yaml

kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    -n gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "configmap", "default": "any"}}}}'
    
kubectl rollout restart -n gpu-operator daemonset/nvidia-device-plugin-daemonset


kubectl apply -f ollama-pvc.yaml
kubectl apply -f ollama-deployment.yaml
kubectl apply -f ollama-service.yaml

kubectl apply -f webui-deployment.yaml
kubectl apply -f webui-service.yaml

kubectl get pods


#ollama run deepseek-r1:1.5b
#ollama run granite3.1-moe:1b
#ollama run falcon3:1b