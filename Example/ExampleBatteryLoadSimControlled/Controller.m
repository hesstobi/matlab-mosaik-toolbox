classdef Controller < MosaikUtilities.Controller
	% CONTROLLER   Battery controller
	%   Controls battery voltage and shuts down battery when voltage drops too low.

	properties

		amount = 0
		eid
		init_voltage = 10
		voltage
		shutdown_voltage = 5

	end

	methods

		function this = Controller(varargin)
			% Constructor of the class Controller
            %
            % Parameter:
            %  - varargin: Optional arguments.
            %
            % Return:
            %  - this: Controller object

            this = this@MosaikUtilities.Controller(varargin{:});

		end

		function value = meta(this)
            % Creates meta struct.

            value = meta@MosaikAPI.Simulator(this);
           
            % Add controller meta data
            value.models.Controller.public = true;
            value.models.Controller.params = {'init_voltage','shutdown_voltage'};
            value.models.Controller.attrs = {'voltage'};
            value.models.Controller.any_inputs = true;
        
        end



		function data = get_data(this)
			%

			if isfield(inputs.(this.eid))

				for i = 1:numel(fieldnames(inputs.(this.eid)))

					data.(this.eid).(fieldnames(inputs.(this.eid){i})) = this.(fieldnames(inputs.(this.eid){i}));

				end

			end

		end

		function schedule = makeSchedule(this,inputs)
			% 

			batteries = [fieldnames(inputs.(this.eid).capacitance),[]];

			rels = this.getRelatedWithoutUtility(batteries);
			outputs = [];
			loads = [];

			for i = 1:numel(batteries);

				loads = fieldnames(rels);

				capacitance = inputs.(this.eid).capacitance.(batteries{i});
				init_capacitance = this.getValue(batteries{i},'init_capacitance');
				this.voltage = (capacitance / init_capacitance)^2 * this.init_voltage;

				if ge(this.voltage,this.shutdown_voltage)

					total_consumed_cap = 0;

					for j= 1:numel(loads)

						resistance = this.getValue(loads{j},'resistance');
						consumed_capacitance = (this.voltage / resistance) * this.step_size;

						outputs.(loads{j}).consumed_capacitance = consumed_capacitance;
						total_consumed_cap = total_consumed_cap + consumed_capacitance;

					end

					outputs.(batteries{i}).voltage = this.voltage;
					outputs.(batteries{i}).consumed_capacitance = total_consumed_cap;

				end

			end

			schedule.([strrep(this.sid, '-', '_0x2D_'), '_0x2E_', this.eid]) = outputs;

		end

	end

end