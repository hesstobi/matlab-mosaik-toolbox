classdef Battery < MosaikAPI.Model
	% BATTERY battery model for MOSAIK ModelSimulator
	%   Models a battery with given parameters initial capacitance Q_0 and voltage at that capacitance U_0.
	%   The voltage U drops with decreasing capacitance Q in the form U = U_0 * ((Q/Q_0) ^ 0.5).

	properties
		init_voltage;
		init_capacitance;
		capacitance;
		voltage;
		data_out;
	end

	methods 

		function this = Battery(eid,varargin)
			this = this@MosaikAPI.Model(eid);
            
            p = inputParser;
            addOptional(p,'init_voltage',10,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addOptional(p,'init_capacitance',1000,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.init_voltage = p.Results.init_voltage;
            this.init_capacitance = p.Results.init_capacitance;
            this.voltage = init_voltage;
            this.capacitance = init_capacitance;
		end

		function step(this, varargin)
			p = inputParser;
			addOptional(p,'consumed_capacitance',struct); %Add validation function
			parse(p,varargin{:});

			consumed_capacitance = sum(cell2mat(struct2cell(p.consumed_capacitance)));
			this.capacitance = this.capacitance - consumed_capacitance;
			this.voltage = (((this.capacitance / init_capacitance) ^ 0.5) * this.init_voltage); % Battery voltage U
			this.data_out.voltage = this.voltage;
			this.data_out.state_of_charge  = capacitance;
		end

	end

	methods (Static)

		function value = meta()
			value.public = true;
			value.attrs = {'voltage', 'data_out'};
			value.params = {'init_capacitance', 'init_voltage'};
			value.any_inputs = false; %CHECK this
		end

	end

end
