classdef Controller < MosaikUtilities.Controller
	% CONTROLLER   Battery controller
	%   Controls battery voltage and shuts down battery when voltage drops too low.

	properties

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
            value.models.Controller.attrs = {'battery_cap','load_res','voltage'};
        
        end

		function ctrl_list = create(this,num,model,varargin)
			%

			if ~strcmp(model,'Controller')
				error('Can only create controller.');
			end

			ctrl_list.eid = 'Controller';
			ctrl_list.type = 'Controller';
			ctrl_list.rel = {};
			ctrl_list = {ctrl_list,[]};

		end


		function time_next_step = step(this,time,varargin)
			%

			data = this.concentrateInputs(inputs);
			schedule = this.makeSchedule(data);
			this.mosaik.set_data(schedule);

			time_next_step = this.step_size + time;

		end

		function data = get_data(this)
			%

		end

		function schedule = makeSchedule(this,inputs)
			%

			batteries = fieldnames(inputs.Controller.battery_cap);
			rels = this.mosaik.get_related_entities(batteries);
			disp(savejson('',rels));
		end


	end

end