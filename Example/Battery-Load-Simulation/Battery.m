classdef Battery < MosaikAPI.Model
	% BATTERY   Battery model for MOSAIK ModelSimulator
	%   Models a battery with given parameters initial capacitance Q_0 and voltage at that capacitance U_0.
	%   The voltage U drops with decreasing capacitance Q in the form U = U_0 * ((Q/Q_0) ^ 0.5).

	properties
		init_voltage;		% Initial battery voltage
		init_capacitance;	% Initial battery capacitance
		voltage;			% Current battery voltage
		capacitance;		% Current battery capacitance
		data_out;			% Struct containing current voltage and current capacitance
	end

	methods 

		function this = Battery(sim,eid,varargin)
			% Constructor of the class Battery
			%
			% Parameter:
			%  - sim: Related simulator
			%  - eid: Model entity ID
			%  - varargin: Unspecified model parameters.
			%
			% Return:
			%  - this: Battery object

			this = this@MosaikAPI.Model(sim,eid);
            
            p = inputParser;
            addOptional(p,'init_voltage',10,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addOptional(p,'init_capacitance',1000,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.init_voltage = p.Results.init_voltage;
            this.init_capacitance = p.Results.init_capacitance;
            this.voltage = this.init_voltage;
            this.capacitance = this.init_capacitance;
		end

		function step(this,varargin)
			% Removes capacitance consumed by connected loads.
			p = inputParser;
			addOptional(p,'consumed_capacitance',struct); %Add validation function
			parse(p,varargin{:});

			consumed_capacitance = sum(cell2mat(struct2cell(p.Results.consumed_capacitance)));
			this.capacitance = this.capacitance - consumed_capacitance;
			this.voltage = (((this.capacitance / init_capacitance) ^ 0.5) * this.init_voltage); % Battery voltage U
		end

	end

	methods (Static)

		function value = meta()
			% Adds model meta content to meta struct.
			value.public = true;
			value.attrs = {'voltage', 'capacitance'};
			value.params = {'init_capacitance', 'init_voltage'};
			value.any_inputs = false; %CHECK this
		end

	end

end
