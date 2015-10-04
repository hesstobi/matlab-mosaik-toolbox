classdef Load < MosaikAPI.Model
	% LOAD electrical load model for MOSAIK ModelSimulator
	%   Simulates a load with given parameters resistance R, operating voltage U_R and tolerance delta, which together
	%   define the range operating voltages.
	%   Based on the battery given voltage U, resistance R and time (step.size) t , the load consumes capacitance Q in the form
	%   Q = (U/R) * t.
	%   The simulator has the attribute 'val_in', which is the battery voltage U.
	%   To show the functionality of asynchronous requests, the simulator requests the battery it's connected to via get_related_entities
	%   and feeds it the consumed capacitance Q via set_data.

	properties
		resistance;
		voltage;
		tolerance;
		voltage_in;
		consumed_capacitance;
		data_out;
	end

	methods 

		function this = Load(sim,eid,varargin)
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
			p = inputParser;
			addOptional(p,'voltage_in',struct); %Add validation (only one voltage_in allowed)
			parse(p,varargin{:});

			voltage_in = cell2mat(struct2cell(p.voltage_in));
			if ge(voltage_in,(this.voltage*(1-this.tolerance))) && le (voltage_in,(this.voltage*(1+this.tolerance)))
				this.consumed_capacitance = ((voltage_in/this.resistance)*sim.step_size;
			end

			rels = sim.as_get_related_entities(this.eid);
			fn_src_full_id = fieldnames(rels);
			l = struct;
			for j = 1:numel(fn_src_full_id)
				if strcmp(rels.(fn_src_full_id{j}).type, 'Battery')
					l.(fn_src_full_id{j}) = struct('consumed_capacitance', this.consumed_capacitance);
				end			
			end
			m = struct;
			m.([strrep(sim.sid, '-', '_0x2D_'), '_0x2E_', this.eid]) = l; % '_0x2D_' is hex for '-'; '_0x2E_' is hex for '.'; JSONLab will convert it, MATLab can not have points in struct fields.
			sim.as_set_data(m);

			this.data_out.consumed_capacitance = this.consumed_capacitance;
		end

	end

	methods (Static)

		function value = meta()
			value.public = true;
			value.attrs = {'voltage_in','data_out'};
			value.params = {'resistance','voltage','tolerance'};
			value.any_inputs = false;
		end

	end
end
