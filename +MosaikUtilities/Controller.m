classdef Controller < MosaikAPI.Simulator
	% CONTROLLER   Controller Superclass
	%   Provides data fetching and controlling scheduling methods

	properties

		step_size = 1	% Simulator step size

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

            this = this@MosaikAPI.Simulator(varargin{:});
            
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

			if ~isempty(varargin)
				schedule = this.makeSchedule(varargin{1});
				this.mosaik.set_data(schedule);
			end

			time_next_step = this.step_size + time;

		end

		function value = getValue(this,id,attr)
			%

			output.(id) = {attr,[]};
			data = this.mosaik.get_data(output);
			value = data.(id).(attr);
            
        end

        function entities = getRelatedWithoutUtility(this,entities)
        	%

        	rels = this.mosaik.get_related_entities(entities);
        	rel  = fieldnames(rels);

        	for i = 1:numel(rel)

        		if ~strcmp(rels.(rel{i}).type,'Controller') && ~strcmp(rels.(rel{i}).type,'Collector')

        			entities.(rel{i}) = rels.(rel{i});

        		end

        	end

        end

	end

	methods (Abstract)

		% Abstract scheduling method.
		makeSchedule(this,inputs);

	end

end