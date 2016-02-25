classdef Battery < MosaikAPI.Model
	% BATTERY   Battery model for MOSAIK ModelSimulator
	%   Models a battery with given parameters initial capacitance Q_0.

	properties

		init_capacitance			% Initial battery capacitance
		capacitance 				% Current battery capacitance
		voltage						% Current battery voltage
		consumed_capacitance = 0	% Capitance consumed by loads in current step

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
            addOptional(p,'init_capacitance',1000,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.init_capacitance = p.Results.init_capacitance;
            this.capacitance = this.init_capacitance;

		end

		function step(this,varargin)
			% Removes capacitance consumed by connected loads.

			this.capacitance = this.capacitance - this.consumed_capacitance;

		end

	end

	methods (Static)

		function value = meta()
			% Adds model meta content to meta struct.

			value.public = true;
			value.attrs = {'init_capacitance','capacitance','voltage'};
			value.params = {'init_capacitance'};
			value.any_inputs = false; %CHECK this
			
		end

	end

end
