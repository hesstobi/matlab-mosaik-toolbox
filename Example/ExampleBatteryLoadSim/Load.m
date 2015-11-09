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
		voltage					% Load voltage
		tolerance				% Load voltage tolerance
		voltage_in				% Supplied battery voltage
		consumed_capacitance	% By load consumed battery capacitance

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
            addOptional(p,'voltage',10,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addOptional(p,'tolerance',0.1,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.resistance = p.Results.resistance;
            this.voltage = p.Results.voltage;
            this.tolerance = p.Results.tolerance;
            this.consumed_capacitance  = 0;

		end

		function step(this,varargin)
			% Checks if supplied voltage is within voltage tolerance margin. Calculates consumed capacitance in this step based on supplied voltage.

			if ge(this.voltage_in,(this.voltage*(1-this.tolerance))) && le (this.voltage_in,(this.voltage*(1+this.tolerance)))
				this.consumed_capacitance = ((this.voltage_in/this.resistance)*this.sim.step_size); %#ok<*PROP>
			end

			rels = this.sim.mosaik.get_related_entities(this.eid);
			fn_src_full_id = fieldnames(rels);
			l = struct;
			for j = 1:numel(fn_src_full_id)
				if strcmp(rels.(fn_src_full_id{j}).type, 'Battery')
					l.(fn_src_full_id{j}) = struct('consumed_capacitance', this.consumed_capacitance);
				end			
			end
			output = struct;
			output.([strrep(this.sim.sid, '-', '_0x2D_'), '_0x2E_', this.eid]) = l; % '_0x2D_' is hex for '-'; '_0x2E_' is hex for '.'; JSONLab will convert it, MATLab can not have dots in struct fields.
			this.sim.mosaik.set_data(output);

		end

	end

	methods (Static)

		function value = meta()
			% Adds model meta content to meta struct.

			value.public = true;
			value.attrs = {'voltage_in','voltage','consumed_capacitance'};
			value.params = {'resistance','voltage','tolerance'};
			value.any_inputs = false;

		end

	end
	
end
