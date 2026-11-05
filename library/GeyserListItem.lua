---@meta Geyser.ListItem

---@class Geyser.ListItem.Constraints
---@field [string] any
---@field name string? The item's name. One is made up if not given.
---@field height number|string? The height constraint. Default "1c".
---@field message string? The text to show.
---@field stylesheet string? The Qt stylesheet to apply.
---@field fgColor string? The text colour.
---@field font string? The font.
---@field fontSize number? The font size.
---@field onInsert fun(item: Geyser.ListItem)? Called with the item once it is built.
---@field onDismiss fun(item: Geyser.ListItem, done: fun())? What `dismiss()` consults. `done` deletes the item.

--- A row of a Geyser.List: a Geyser.Label that is one line tall unless told
--- otherwise, and that lets its owner have a say in how it arrives and goes. It also
--- has everything a Geyser.Label has. The SDK doesn't declare that as a class to
--- inherit from, so whatever isn't listed here comes through as `any`.
---@class Geyser.ListItem
---@field [string] any
---@field name string The item's name.
---@field message string? The text it last showed.
---@field stylesheet string? The stylesheet applied, its stripe included.
---@field ownStyleSheet string? The stylesheet set on the item, without its stripe.
---@field stripe string? The stylesheet its list gave it.
---@field dismissing boolean? True once `dismiss()` has handed it to its `onDismiss`.
---@field deleted boolean? True once it has been deleted, for anything still working on it to check.
---@field onInsert fun(item: Geyser.ListItem)? Called with the item once it is built.
---@field onDismiss fun(item: Geyser.ListItem, done: fun())? What `dismiss()` consults.
Geyser.ListItem = {}

--- Creates a new list item.
---@param cons Geyser.ListItem.Constraints? The constraints.
---@param container table? The Geyser.List, or other container, to put it in.
---@return Geyser.ListItem? item The new item, or nil if its name was refused.
---@return string? err Why the name was refused.
function Geyser.ListItem:new(cons, container) end

--- Overridden constructor to use add2.
---@param cons Geyser.ListItem.Constraints? The constraints.
---@param container table? The Geyser.List, or other container, to put it in.
---@return Geyser.ListItem? item The new item, or nil if its name was refused.
---@return string? err Why the name was refused.
function Geyser.ListItem:new2(cons, container) end

--- The Geyser.List the item is in.
---@return Geyser.List? list The list, or nil if it isn't in one.
function Geyser.ListItem:getList() end

--- The item's position in its list.
---@return integer? index The position, from 1, or nil if it isn't in a list.
function Geyser.ListItem:getIndex() end

--- Moves the item to a position in its list.
---@param index integer The position to move it to, from 1.
---@return boolean? moved True, or nil and why not.
---@return string? err Why it wasn't moved.
function Geyser.ListItem:moveTo(index) end

--- Whether the item is selected in its list.
---@return boolean selected Whether it is selected.
function Geyser.ListItem:isSelected() end

--- Sets what is called with the item once it is built.
---@param callback fun(item: Geyser.ListItem)? Called with the item.
function Geyser.ListItem:setOnInsert(callback) end

--- Sets what `dismiss()` consults.
---@param callback fun(item: Geyser.ListItem, done: fun())? Called with the item and a `done` function, which deletes the item.
function Geyser.ListItem:setOnDismiss(callback) end

--- Sets the item's stylesheet, keeping any stripe its list has given it underneath.
---@param css string? The Qt stylesheet. Without one, the current one is applied again.
function Geyser.ListItem:setStyleSheet(css) end

--- Sets the stylesheet that goes under the item's own. Its list calls this.
---@param stripe string? The Qt stylesheet.
function Geyser.ListItem:setStripe(stripe) end

--- Prints a message to the item. Does nothing when asked to show the plain text it already shows.
---@param message string? The message to print.
---@param color string? The colour to use.
---@param format string? The format list to use.
function Geyser.ListItem:echo(message, color, format) end

--- Prints a message with cecho colours. Does nothing when asked to show the text it already shows.
---@param message string? The message to print.
---@return boolean? ok True, or nil and an error message if the label no longer exists.
---@return string? err The error message.
function Geyser.ListItem:cecho(message) end

--- Prints a message with decho colours. Does nothing when asked to show the text it already shows.
---@param message string? The message to print.
---@return boolean? ok True, or nil and an error message if the label no longer exists.
---@return string? err The error message.
function Geyser.ListItem:decho(message) end

--- Prints a message with hecho colours. Does nothing when asked to show the text it already shows.
---@param message string? The message to print.
---@return boolean? ok True, or nil and an error message if the label no longer exists.
---@return string? err The error message.
function Geyser.ListItem:hecho(message) end

--- Resizes the item, and has its list fit a new height.
---@param width number|string? The new width constraint.
---@param height number|string? The new height constraint.
function Geyser.ListItem:resize(width, height) end

--- Raises the item above other windows, keeping its place in the list.
function Geyser.ListItem:raise() end

--- Lowers the item below other windows, keeping its place in the list.
function Geyser.ListItem:lower() end

--- Takes the item out of its list. An `onDismiss` gets the first say, and the item is deleted when it calls `done`. Without one, it is deleted now.
function Geyser.ListItem:dismiss() end

--- Deletes the item now, without consulting `onDismiss`.
function Geyser.ListItem:delete() end
