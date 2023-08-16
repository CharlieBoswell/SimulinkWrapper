function [output] = pController(output, target)
	gain = 0.3
	err = output - target
	output = output + (err * gain)