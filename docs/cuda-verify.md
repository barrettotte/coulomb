# CUDA Verify

Verify that CUDA works inside distrobox as expected.

```sh
# expected
nvidia-smi
```

```sh
# simple test
distrobox create --name gpu-test --image archlinux:latest --nvidia
distrobox enter gpu-test -- nvidia-smi
distrobox enter gpu-test -- ls -l /usr/lib/libcuda.so # verify not 0 bytes
distrobox rm gpu-test
```

```sh
# better test
distrobox create -n cuda-test -i docker.io/nvidia/cuda:12.3.1-base-ubi9 --nvidia
distrobox enter cuda-test -- nvidia-smi
distrobox rm cuda-test
```
