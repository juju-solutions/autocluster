# autocluster
Bring up a kvm cluster appropriate for testing CDK.

## Usage

```
ARCH=arm64 ./autocluster.sh
```

## Notes

* This script needs some love - `NODE_COUNT` should be parameterized, and we might be able to parallelize more things.
