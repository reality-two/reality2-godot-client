# ======================================================================================================================================================
# A Finite State Machine or Automation
# ------------------------------------
#
# First, instantiate a FSM.Automation, then use add_transition to add Transitions.  Note that the actions parameter is an array of callback functions.
# Such functions can be defined as
# var my_func = func(params):
# 	Do your stuff, use the parameters, etc
#	return modified_params
#
# The params variable is a Dictionary where the first function in the list gets the parameters that were sent with the event, and each action in the
# array is passed the returned result of the previosu action.
#
# So, a transition would be added like this:
# my_automation.add_transition("init", "start", "ready", [my_func])
#
# Note that a 'from' state of "*" matches any state, and a 'to' state of "*" leaves the state as it was (but stil executes the actions).
#
# The step function has to be called regularly, such as in a _process function of a node.
#
# When enqueuing an event, you can specify that it will happen in the future, by giving a delay (in seconds).
#
# Dr. Roy C. Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

class_name FSM

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# A Finite State Machine or Automation
# ------------------------------------------------------------------------------------------------------------------------------------------------------
class Automation:
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Attributes
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	var _current_state: String
	func state(): return _current_state
	var _transitions = []
	var _event_queue = []
	func queue_size(): return _event_queue.size()
	var _timed_events = []
	func timers_size(): return _timed_events.size()
	var _debug = false
	func set_debug(val): _debug = val
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	
		
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Constructor
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func _init(debug = false):
		_current_state = "start"
		enqueue("init", {})
		_debug = debug
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Public functions
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Part of the setup, to add the transitions
	func add_transition(from, event, to, actions = []):
		var transition = {"from": from, "event": event, "to": to, "actions": actions}
		if (_debug): print("TRANSITION:   ", transition)
		_transitions.push_back(transition)

	# An an event to the queue
	func enqueue(event: String, parameters = {}, delay = 0):
		if (delay == 0):
			if (_debug): print("ENQUEUEING: ", event, parameters)
			_event_queue.push_back({"event": event, "parameters": parameters})
		else:
			if (_debug): print("TIMING:     ", event, parameters, delay)
			_timed_events.push_back({"event": event, "parameters": parameters, "time": Time.get_ticks_msec() + delay * 1000})
	
	# Should be called every frame (eg in the _process function of a node)
	func step():
		# Check the timed events and queue any that have expired
		for i in range(_timed_events.size() - 1, -1, -1):
			if (_timed_events[i].time <= Time.get_ticks_msec()):
				if(_debug): print("QUEUEING :  ", _timed_events[i].event, _timed_events[i].parameters)
				enqueue(_timed_events[i].event, _timed_events[i].parameters)
				_timed_events.remove_at(i)

		# Check the events and perform transitions
		var event_and_parameters = self._event_queue.pop_front()
		if (event_and_parameters):
			if (_debug): print("EVENT:      ", event_and_parameters.event, ", ", event_and_parameters.parameters)
			_check_transitions(event_and_parameters)
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Private functions
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func _check_transitions(event_and_parameters):
		for transition in _transitions:
			if (_current_state == transition.from || transition.from == "*"):
				if (event_and_parameters.event == transition.event):
					if (_debug): print(transition.from, ":", transition.event, "->", transition.to)
					if(transition.to != "*"):
						_current_state = transition.to
					var previous_result = event_and_parameters.parameters
					for action in transition.actions:
						previous_result = action.call(previous_result)
					break
	# --------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------
