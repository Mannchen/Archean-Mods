<p align="center">
  <img src="InfiniteItems.png" />
</p>

| Component | `InfiniteItems` |
|---|---|
|**Module**|`MANNCHEN_infinite`|
|**Mass**|1 kg|
|[**Size**](# "Based on the component's occupancy in a fixed 25cm grid.")|25 x 25 x 25 cm|
|**Push/Pull Item**|Initiate Push/Pull|
#
---

# Description
Infinite Items is a creative component that can push and pull a user specified amount of items 

# Usage
Connect the Item port. Then you can specify the name and amount of items provided via the **V** menu.  
You can also configure the component via the data port if `Allow dataport configuration` is checked.  
If no item name is provided `Pull` will pull any item.  
Item amount is per tick (25 times per second)

> Some features like item properties, max mass and simultaneous push and pull are only available using dataport configuration

### List of inputs
| Channel | Function | Value |
|---|---|---|
| 0 | Enable input output | `0` or `1` |
| 1 | Push Items | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) (`.itemName{}.properties{}.count{}`) |
| 2 | Pull Items | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) (`.itemName{}.maxCount{}.maxMass{}`) |

> Pull Items: if `maxMass` is specified (and not `0`) then `maxCount` is ignored
> Pull Items: if `maxCount` is specified and `0` then as many items as possible are pulled

### List of outputs
| Channel | Function | Value |
|---|---|---|
| 0 | Items sent | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) |
| 1 | Items received | [Key-value](https://wiki.archean.space/xenoncode/documentation.md#key-value-objects) |
