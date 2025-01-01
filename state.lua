local statemachine = {}

function statemachine:changestate(state, variable)
	self.state = state
	self.state:changedstate(variable)
end

return statemachine
