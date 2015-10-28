classdef ExampleBatteryLoadSim < MosaikAPI.ModelSimulator
	% EXAMPLEBATTERYLOADSIM   Advanced simulator.
	%   Simulator that shows complex dependecies between model entities.

	properties

        providedModels = {'Battery','Load'}	% Models which are provided by the simulator

    end
     
    
    methods

		function this = ExampleBatteryLoadSim(varargin)
			% Constructor of the class ExampleBatteryLoadSim

 			this = this@MosaikAPI.ModelSimulator(varargin{:});

		end

	end

end
