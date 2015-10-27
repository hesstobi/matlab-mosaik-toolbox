classdef ExampleBatteryLoadSim < MosaikAPI.ModelSimulator

	properties
        providedModels = {'Battery','Load'};    
    end
     
    
    methods 
		function this = ExampleBatteryLoadSim(varargin)
 			this = this@MosaikAPI.ModelSimulator(varargin{:});
		end
	end

end
