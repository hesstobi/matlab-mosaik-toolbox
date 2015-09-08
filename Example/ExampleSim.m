classdef ExampleSim < MosaikAPI.ModelSimulator

	properties
        step_size = 1
        providedModels = {'Model'};    
    end
     
    
    methods 
		function sim = ExampleSim(varargin)
 			sim = sim@MosaikAPI.ModelSimulator(varargin{:});
		end
	end
      
	methods

		

		

	end

	methods

		function extra = wtimes(~, args, kwargs)
			word = args;
			extra = '';
			if ~isfield(kwargs, 'times')
				times = 1;
			else
				times = kwargs.times;
			end
			for i = 1:times
				extra = strcat(extra, word);
			end
        end
       

	end

end
