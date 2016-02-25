classdef Load < MosaikAPI.Model
	% LOAD  Electrical load model for MOSAIK ModelSimulator.
	%   Simulates a load with given parameters resistance R, operating voltage U_R and tolerance delta, which together
	%   define the range operating voltages.
	%   Based on the battery given voltage U, resistance R and time (step.size) t , the load consumes capacitance Q in the form
	%   Q = (U/R) * t.
	%   To show the functionality of asynchronous requests, the simulator requests the battery it is connected to via get_related_entities
	%   and feeds it the consumed capacitance Q via set_data.

	properties

		resistance				% Load resistance
		consumed_capacitance	% By load consumed battery capacitance
		total_consumed_cap		% Total by load consumed battery capaciance

	end

	methods 

		function this = Load(sim,eid,varargin)
			% Constructor of the class Load
			%
			% Parameter:
			%  - sim: Related simulator
			%  - eid: Model entity ID
			%  - varargin: Unspecified model parameters.
			%
			% Return:
			%  - this: Load object

			this = this@MosaikAPI.Model(sim,eid);
            
            p = inputParser;
            addOptional(p,'resistance',1000,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.resistance = p.Results.resistance;
            this.consumed_capacitance  = 0;
            this.total_consumed_cap  = 0;

		end

		function step(this,varargin)
			%

			this.total_consumed_cap = this.total_consumed_cap + this.consumed_capacitance;

		end

	end

	methods (Static)

		function value = meta()
			% Adds model meta content to meta struct.

			value.public = true;
			value.attrs = {'resistance','consumed_capacitance','total_consumed_cap'};
			value.params = {'resistance'};
			value.any_inputs = false;

		end

	end
	
end
