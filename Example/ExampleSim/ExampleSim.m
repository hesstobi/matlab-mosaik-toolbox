classdef ExampleSim < MosaikAPI.ModelSimulator

	properties
        providedModels = {'Model'};    
    end
     
    
    methods

		function this = ExampleSim(varargin)
 			this = this@MosaikAPI.ModelSimulator(varargin{:});
		end

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
