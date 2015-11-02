classdef ExampleSim < MosaikAPI.ModelSimulator
	% EXAMPLESIM   Simple example simulator.
	%   Simulator to demonstrate the basic functions of MOSAIK.

	properties

		providedModels = {'Model'}	% Models which are provided by the simulator

	end


	methods

		function this = ExampleSim(varargin)
			% Constructor of the class ExampleSim

			this = this@MosaikAPI.ModelSimulator(varargin{:});

		end

		function extra = wtimes(~,word,varargin)
			% Method to show extra functions in simulators. Cats given string a given amount of times.

			p = inputParser;
			addOptional(p,'amount',2,@(x)validateattributes(x,{'numeric'},{'scalar'}));
			parse(p,varargin{:});

			amount = p.Results.amount;

			extra = '';
			for i = 1:amount
				extra = strcat(extra, word);
			end
			
		end

	end

end
