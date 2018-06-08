# autocluster
Bring up a kvm cluster appropriate for testing CDK.

## Usage

```
ARCH=arm64 ./autocluster.sh
```

## Notes

This script needs some love:
* `NODE_COUNT` should be parameterized.
* `ubuntu` user assumed, along with `/home/ubuntu/.ssh/id_rsa.pub` etc.
* We might be able to parallelize more things.
