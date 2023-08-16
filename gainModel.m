function [modelOut1, modelOut2] = gain(modelIn1, modelIn2)
	gain1 = 10;
	gain2 = 1;
	modelOut1 = modelIn1 * gain1;
	modelOut2 = modelIn2 * gain2;    
