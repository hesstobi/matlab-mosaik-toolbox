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

		function ctrl_list = create(this,num,model,varargin)
			%

			if ~strcmp(model,'Controller')
				error('Can only create controllers.');
			end

			ctrl_list = [];

			for i = this.amount:this.amount+num-1

				this.eid = ['Controller','_',num2str(i)];
				ctrl.eid = this.eid;
				ctrl.type = 'Controller';
				ctrl.rel = {};
				ctrl_list{end+1} = ctrl;

			end

			ctrl_list{end+1} = [];

			disp(this.amount);
			this.amount = this.amount + num;
			disp(this.amount);

		end


		function time_next_step = step(this,time,varargin)
			%

			disp(savejson('',varargin{1}));

			if ~isempty(varargin)
				schedule = this.makeSchedule(varargin{1});
				this.mosaik.set_data(schedule);
			end

			time_next_step = this.step_size + time;

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

			batteries = [fieldnames(inputs.(this.eid)),[]];

			rels = this.mosaik.get_related_entities(batteries);
			outputs = [];
			loads = [];

			for i = 1:numel(batteries)-1;

				loads = fieldnames(rels.(batteries{i}));
				loads = cellfun(@(x) x{end},cellfun(@(y) strsplit(y,'_0x2E_'),loads,'UniformOutput',false), ...
                	'UniformOutput',false);

				capacitance = inputs.Controller.(batteries{i});
				init_capacitance = this.getValue(batteries{i},'init_capacitance');
				this.voltage = (capacitance / init_capacitance)^2 * this.init_voltage;

				if ge(this.voltage,this.shutdown_voltage)

					total_consumed_cap = 0;

					for j= 1:numel(loads)

						if strcmp(loads{j},'Controller')

						else

							resistance = this.getValue(loads{j},'resistance');
							consumed_capacitance = (voltage / resistance) * this.step_size;

							outputs.(loads{j}).consumed_capacitance = consumed_capacitance;
						
						end

						total_consumed_cap = total_consumed_cap + consumed_capacitance;

						outputs.(batteries{i}).consumed_capacitance = total_consumed_cap;

					end

				end

			end

			schedule.([strrep(this.sim.sid, '-', '_0x2D_'), '_0x2E_', this.eid]) = outputs;

		end

	end

end