classdef BatteryLoadSim < MosaikAPI.ModelSimulator

	properties
        providedModels = {'Battery','Load'};    
    end
     
    
    methods 
		function this = BatteryLoadSim(varargin)
 			this = this@MosaikAPI.ModelSimulator(varargin{:});
		end
	end

end
