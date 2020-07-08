# Revise HyperBus Implementation v2

Goals:
- have a working HB IP
- as portable as possible
- only few dependencies
- no interfaces
- AXI for data
- REGBUS for configuration
- low amount of cancer
- save CDCs
- try to keep proven phi
- verify we are spec conform 

TODOs:
- remove interfaces
- remove size converter
- replace config registers (they are non-maintainable rn)
- replace `hyperbus_axi` module - this is "the digital" part




# Old README:

## Revise HyperBus Implementation

### Getting Started

Checkout the repository and initialize all submodules:

```
git submodule update --init --recursive
```

TBD

### Contribution Style

Please consider the following [style guidelines](https://github.com/pulp-platform/style-guidelines).