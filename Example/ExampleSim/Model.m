classdef Model < MosaikAPI.Model
	% MODEL   Example model for ExampleSim
	%   Simple example model that adds a defined value to its absolute value every step.
	
	properties

		delta = 1	% Constant increment value
		val			% Increasing value

	end
	
	methods 
	   
		function this = Model(sim,eid,varargin)
			% Constructor of the class Model.

			this = this@MosaikAPI.Model(sim,eid);
			
			p = inputParser;
			addOptional(p,'init_value',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
			parse(p,varargin{:});
			
			this.val = p.Results.init_value;   

		end
		
		
		function step(this,~,varargin)
			% Adds defined value to return value.

			this.val = this.val + this.delta; 

		end
		
	end

	methods (Static)
		
		function value = meta()
			% Adds model meta content to meta struct.

			value.public = true;
			value.attrs = {'delta', 'val'};
			value.params = {'init_value'};
			value.any_inputs = false;

		end

	end
	
end
