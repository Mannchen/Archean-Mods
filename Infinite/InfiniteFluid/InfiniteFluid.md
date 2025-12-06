<p align="center">
  <img src="InfiniteFluid.png" />
</p>

| Component | `InfiniteFluid` |
|---|---|
|**Module**|`Archean_mod`|
|**Mass**|1 kg|
|[**Size**](# "Based on the component's occupancy in a fixed 25cm grid.")|25 x 25 x 25 cm|
|**Push/Pull Fluid**| accept Push/Pull, initiate Push/Pull|
#
---

# Description
Infinite Fluid is a creative component that can provide and consume a user specified amount of fluid.

# Usage
Connect the fluid port. Then you can configure the component via the **V** menu or via dataport inputs if `Allow dataport configuration` is checked.

> The component can output nonexistant fluids and `Output Fluid` updates while you are typing. So it is a good idea to disable the component while you change the `Output Fluid` field.

### List of inputs
| Channel | Function | Value |
|---|---|---|
| 0 | Enable input output | `0` or `1` |
| 1 | Output Fluid | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) (`.H2O{100}.CO2{5}`) |
| 2 | Output Fluid temperature (Kelvin) | Number |
| 3 | Accept Fluid (kg/s) | Number |
| 4 | Push Fluid | `0` or `1` |
| 5 | Pull Fluid | `0` or `1` |

### List of outputs
| Channel | Function | Value |
|---|---|---|
| 0 | Fluid sent | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) |
| 1 | Fluid received | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) (`.H2O{.m{27}.t{293.15}}`)|
