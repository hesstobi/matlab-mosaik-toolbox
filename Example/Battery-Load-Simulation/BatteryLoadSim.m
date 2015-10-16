classdef BatteryLoadSim < MosaikAPI.ModelSimulator

	properties
        step_size = 1
        providedModels = {'Battery','Load'};    
    end
     
    
    methods 
		function sim = BatteryLoadSim(varargin)
 			sim = sim@MosaikAPI.ModelSimulator(varargin{:});
		end
	end

end
