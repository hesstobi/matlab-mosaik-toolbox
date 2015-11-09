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

			disp(savejson('',varargin{1}));

			if ~isempty(varargin)
				schedule = this.makeSchedule(varargin{1});
				this.mosaik.set_data(schedule);
			end

			time_next_step = this.step_size + time;

		end

		function data = get_data(this)
			%

		end

		function schedule = makeSchedule(this,inputs)
			% For now only one battery connected

			batteries = {fieldnames(inputs.Controller.battery_cap),[]};
			disp(numel(batteries));

			rels = this.mosaik.get_related_entities(batteries);
			outputs = [];

			for i = 1:numel(batteries)-1;
				outputs{end} = fieldnames.rels.(batteries{i});
				disp(savejson('',outputs));
				outputs = cellfun(@(x) x{end},cellfun(@(y) strsplit(y,'_0x2E_'),rels,'UniformOutput',false), ...
                	'UniformOutput',false);
				disp(savejson('',outputs));

				for i = 1:numel(outputs)
					if strcmp(outputs{i}{j},'Controller')
						outputs{i}{j} = [];
					else
						outputs{i}{j} = strrep(outputs{i}{j}, '_0x2E_','.');
						outputs{i}{j} = strrep(outputs{i}{j}, '_0x2D_','-');
						resistance = this.getResistance(outputs{i}{j});
					
					end

				end

			end

			disp(savejson('',rels));
		end

		function resistance = getResistance(this,id)
			output.(id) = 'resistance';
			data = this.mosaik.get_data(output);
			resistance = data.(id).resistance;
		end



	end

end