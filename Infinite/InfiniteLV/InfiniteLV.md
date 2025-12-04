<p align="center">
  <img src="InfiniteLV.png" />
</p>

| Component | `InfiniteLV` |
|---|---|
|**Module**|`Archean_mod`|
|**Mass**|1 kg|
|[**Size**](# "Based on the component's occupancy in a fixed 25cm grid.")|25 x 25 x 25 cm|
#
---

# Description
Infinite LV is a creative component that can provide or consume a user specified amount of LV power

# Usage
Connect the LV port. Then you can specify the amount of power consumed or provided using the **V** menu or via dataport input

### List of inputs
| Channel | Function | Value |
|---|---|---|
| 0 | Enable input output | `0` or `1` |
| 1 | Output Power (Watts) | Number |
| 2 | Output Voltage | Number |
| 3 | Consume Power (Watts) | Number |

### List of outputs
| Channel | Function |
|---|---|
| 0 | Power sent (Watts) |
| 1 | Power consumed (Watts) |
