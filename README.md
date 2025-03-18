## How to execute

To run this project, first clone this repository:

```
git clone https://github.com/heliohsilva/distributed-system-demo.git
```

You will also need to install (if you don't have made it yet) some tool to allow you to run
kubernetes locally. For this tutorial, I will use Minikube.

### Installing minikube

Access the minikube docs at get started module and follow the steps to install it into your machine


```
https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download
```

### Starting the project

First of all, we need to init a minikube container:

```
minikube start --cpus='6' --gpus='all' --memory='4096'
```

Now, we should be able to execute kubectl commands. You can try it to check if the container have started as
it should do.

Having the container running, we can start to set it up. First, set it to allow nvidia gpus:

```
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait --generate-name -n gpu-operator --create-namespace nvidia/gpu-operator

```

Now, we configure it to make the time slicing, that is defined in our configmap.yaml file:

```
kubectl create -n gpu-operator -f configmap.yaml
```

Then, we patch it up and then restart the gpu-operator module:

```
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    -n gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "configmap", "default": "any"}}}}'

kubectl rollout restart -n gpu-operator daemonset/nvidia-device-plugin-daemonset
```

Now, if we run `kubectl describe node` we should see something like:

```
nvidia.com/gpu.product=NVIDIA-GeForce-GTX-1650-SHARED
nvidia.com/gpu.replicas=4
nvidia.com/gpu.sharing-strategy=time-slicing

```

This show us that the time slicing have done succefully, slicing our gpu into 4 replicas, as defined in our configmap.yaml. If this configs does not appear for you immediately, wait few seconds and it should be work.

Now, we have to apply all other services and deployment files, and then it done.
```
kubectl apply -f ollama-pvc.yaml
kubectl apply -f ollama-deployment.yaml
kubectl apply -f ollama-service.yaml

kubectl apply -f webui-deployment.yaml
kubectl apply -f webui-service.yaml

```

Now, we can run `kubectl get pods` and we should see 5 pods running at our node, being 4 pods running ollama containers and another running our frontend client.
