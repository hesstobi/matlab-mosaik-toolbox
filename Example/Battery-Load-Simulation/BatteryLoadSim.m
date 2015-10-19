classdef BatteryLoadSim < MosaikAPI.ModelSimulator

	properties
        providedModels = {'Battery','Load'};    
    end
     
    
    methods 
		function sim = BatteryLoadSim(varargin)
 			sim = sim@MosaikAPI.ModelSimulator(varargin{:});
		end
	end

end
