---@meta Geyser.List

--- A row of a list: usually a Geyser.ListItem, but any Geyser window can be one.
---@alias Geyser.ListRow Geyser.ListItem|table
---@alias Geyser.ListSelectionMode "none"|"single"|"multi"

---@class Geyser.List.Constraints
---@field [string] any
---@field name string? The list's name. One is made up if not given.
---@field x number|string? The x constraint.
---@field y number|string? The y constraint.
---@field width number|string? The width constraint.
---@field height number|string? The height constraint.
---@field scrollbarWidth number? Pixels kept clear for the vertical scrollbar, while there is one. Default 20.
---@field frameWidth number? Pixels the scroll box's frame takes from the room inside it, edges together. Default 4.
---@field selectionMode Geyser.ListSelectionMode? How much of the list can be selected. Default "none".
---@field sortBy (fun(a: Geyser.ListRow, b: Geyser.ListRow): boolean)? Keeps the list in this order. Given two rows, says whether the first goes first.
---@field stripes string[]? Stylesheets for rows to take in turn by position.
---@field onSelectionChange (fun(list: Geyser.List, item: Geyser.ListRow, selected: boolean))? Told when a row's selected state changes.

--- A scrolling vertical list. Anything created in it joins its content as a row. It
--- also has everything a Geyser.Container has. The SDK doesn't declare that as a class
--- to inherit from, so whatever isn't listed here comes through as `any`.
---@class Geyser.List
---@field [string] any
---@field name string The list's name.
---@field scrollbarWidth number Pixels kept clear for the vertical scrollbar, while there is one.
---@field frameWidth number Pixels the scroll box's frame takes from the room inside it, edges together.
---@field selectionMode Geyser.ListSelectionMode How much of the list can be selected.
---@field sortBy (fun(a: Geyser.ListRow, b: Geyser.ListRow): boolean)? The order the list keeps itself in.
---@field stripes string[]? The stylesheets rows take in turn by position.
---@field onSelectionChange (fun(list: Geyser.List, item: Geyser.ListRow, selected: boolean))? Told when a row's selected state changes.
---@field scrollBox table The Geyser.ScrollBox the list is built on.
---@field content table The Geyser.VBox holding the rows.
---@field selected table<string, boolean> The names of the selected rows.
Geyser.List = {}

--- Creates a new list.
---@param cons Geyser.List.Constraints? The constraints.
---@param container table? The Geyser container to put the list in.
---@return Geyser.List? list The new list, or nil if a name was refused.
---@return string? err Why the name was refused.
function Geyser.List:new(cons, container) end

--- Overridden constructor to use add2.
---@param cons Geyser.List.Constraints? The constraints.
---@param container table? The Geyser container to put the list in.
---@return Geyser.List? list The new list, or nil if a name was refused.
---@return string? err Why the name was refused.
function Geyser.List:new2(cons, container) end

--- Adds a window to the list as a row, at the end unless the list has a `sortBy`.
---@param window table The window to add.
---@param cons table? Constraints for the window.
function Geyser.List:add(window, cons) end

--- Adds a window to the list as a row, by way of `Geyser:add2`.
---@param window table The window to add.
---@param cons table? Constraints for the window.
---@param passAdd2 boolean? Whether the window's children inherit add2.
---@param exclude table? Window types that keep their own add.
function Geyser.List:add2(window, cons, passAdd2, exclude) end

--- Creates a Geyser.ListItem in the list.
---@param cons Geyser.ListItem.Constraints? The item's constraints.
---@return Geyser.ListItem? item The new item, or nil if its name was refused.
---@return string? err Why the name was refused.
function Geyser.List:addItem(cons) end

--- Creates a Geyser.ListItem at a position in the list. A list with a `sortBy` puts it where that says instead.
---@param cons Geyser.ListItem.Constraints? The item's constraints.
---@param index integer The position to put it at, from 1.
---@return Geyser.ListItem? item The new item, or nil if its name was refused.
---@return string? err Why the name was refused.
function Geyser.List:insertItem(cons, index) end

--- Moves a row to a position in the list. A list with a `sortBy` refuses.
---@param item Geyser.ListRow|string The row, or its name.
---@param index integer The position to move it to, from 1. Past either end means that end.
---@return boolean? moved True, or nil and why not.
---@return string? err Why it wasn't moved.
function Geyser.List:moveItem(item, index) end

--- The rows of the list, in order. The table is a copy.
---@return Geyser.ListRow[] items The rows.
function Geyser.List:getItems() end

--- A row of the list.
---@param index integer|string The row's position, from 1, or its name.
---@return Geyser.ListRow? item The row, or nil if there is no such row.
function Geyser.List:getItem(index) end

--- The number of rows in the list.
---@return integer count The number of rows.
function Geyser.List:getItemCount() end

--- A row's position in the list.
---@param item Geyser.ListRow|string The row, or its name.
---@return integer? index The position, from 1, or nil if it isn't in this list.
function Geyser.List:indexOf(item) end

--- Deletes every row now, without consulting any `onDismiss` or telling `onSelectionChange`.
function Geyser.List:clear() end

--- Dismisses every row: `dismiss()` for those that have it, `delete()` for those that don't.
function Geyser.List:dismissAll() end

--- Sorts the list and lays it out again.
---@param comparator (fun(a: Geyser.ListRow, b: Geyser.ListRow): boolean)? Used this once. Without one, the `sortBy` is used, or failing that the rows' names.
function Geyser.List:sort(comparator) end

--- Sets the order the list keeps itself in from now on, and sorts it.
---@param comparator (fun(a: Geyser.ListRow, b: Geyser.ListRow): boolean)? Without one, the list stops keeping an order.
function Geyser.List:setSortBy(comparator) end

--- Resizes the content to the total height of the rows and lays them out again.
function Geyser.List:fit() end

--- Gives each Geyser.ListItem its stripe for its current position.
function Geyser.List:restripe() end

--- Sets the stylesheets rows take in turn by position.
---@param stripes string[]? The stylesheets. Without any, the rows lose their stripes.
function Geyser.List:setStripes(stripes) end

--- Sets the pixels kept clear for the vertical scrollbar, while there is one.
---@param width number The width in pixels.
function Geyser.List:setScrollbarWidth(width) end

--- Sets the pixels the scroll box's frame takes from the room inside it.
---@param width number The width in pixels, edges together.
function Geyser.List:setFrameWidth(width) end

--- Starts holding back the layout.
function Geyser.List:begin_update() end

--- Stops holding back the layout, and catches up on it.
function Geyser.List:end_update() end

--- Places the list, and catches up on any layout that was held back.
---@param skipChildren boolean? Place only this window.
function Geyser.List:reposition(skipChildren) end

--- Makes clicking an item select it, unless it has a click callback of its own.
---@param item Geyser.ListItem The item.
function Geyser.List:connectItem(item) end

--- Sets how much of the list can be selected.
---@param mode Geyser.ListSelectionMode The mode.
---@return boolean? set True, or nil and why not.
---@return string? err Why it wasn't set.
function Geyser.List:setSelectionMode(mode) end

--- Selects a row. In "single" mode, that deselects whichever row was selected.
---@param item Geyser.ListRow|string The row, or its name.
---@return boolean? selected True, or nil and why not.
---@return string? err Why it wasn't selected.
function Geyser.List:select(item) end

--- Deselects a row.
---@param item Geyser.ListRow|string The row, or its name.
function Geyser.List:deselect(item) end

--- Selects a row if it isn't selected, and deselects it if it is.
---@param item Geyser.ListRow|string The row, or its name.
---@return boolean? selected Whether it now is, or nil and why not.
---@return string? err Why it couldn't be selected.
function Geyser.List:toggle(item) end

--- Deselects every row.
function Geyser.List:clearSelection() end

--- Whether a row is selected.
---@param item Geyser.ListRow|string The row, or its name.
---@return boolean selected Whether it is selected.
function Geyser.List:isSelected(item) end

--- The selected rows, in list order.
---@return Geyser.ListRow[] items The selected rows.
function Geyser.List:getSelected() end
